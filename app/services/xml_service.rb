require 'nokogiri'

class XmlService
  def self.process(extraction_id)
    extraction = Extraction.find(extraction_id)
    directory = extraction.extracted_path

    xml_files = Dir.glob(File.join(directory, '*.xml'))
    total_files = xml_files.count

    # Create batch log record
    batch_log = XmlBatchLog.create!(
      extraction_id: extraction_id,
      status: 'processing',
      total_files_count: total_files,
    )

    puts "Found #{total_files} XML files to process in #{directory}"

    files_processed = 0

    begin
      # Process in batches to avoid memory issues
      batch_size = 1000
      xml_files.each_slice(batch_size).with_index do |batch, batch_index|
        puts "Processing batch #{batch_index + 1} of #{(total_files / batch_size.to_f).ceil}"

        batch.each_with_index do |file_path, index|
          begin
            process_xml_file(file_path)
            files_processed += 1
            print "." if (index + 1) % 100 == 0

            if (index + 1) % 100 == 0
              batch_log.update_columns(
                files_processed_count: files_processed,
              )
            end
          rescue => e
            puts "\nError processing #{file_path}: #{e.message}"

            # Log failed file
            FailedXmlFileProcessingLog.create!(
              xml_batch_log_id: batch_log.id,
              file_path: File.basename(file_path),
              error_message: e.message,
              error_backtrace: e.backtrace&.join("\n")
            )

            # Update batch log immediately after failure
            batch_log.update_columns(
              files_processed_count: files_processed,
            )
          end
        end

        puts "\nCompleted batch #{batch_index + 1}"

        # Optional: garbage collection after each batch
        GC.start
      end

      # Update batch log with success
      batch_log.update!(
        status: 'completed',
        files_processed_count: files_processed,
      )

      puts "Processing complete! Processed: #{files_processed}, Failed: #{FailedXmlFileProcessingLog.where(xml_batch_log_id: batch_log.id).count}"
    rescue => e
      # Update batch log with failure
      batch_log.update!(
        status: 'failed',
        files_processed_count: files_processed,
        error_message: e.message,
        error_backtrace: e.backtrace&.join("\n")
      )

      puts "Batch processing failed: #{e.message}"
    end
  end

  private

  def self.process_xml_file(file_path)
    doc = Nokogiri::XML(File.read(file_path))

    # Extract relevant data
    data = tax_filing(doc, file_path)
    existing_record = TaxFiling.find_by(ein: data[:ein], tax_year: data[:tax_year])
    if existing_record
      TaxFiling.create!(data)

      # existing_record.update!(data)
    else
      TaxFiling.create!(data)
    end

    # Process the data (save to database, CSV, etc.)
    puts "Processed: #{data[:business_name]} (#{data[:ein]})"
  end

  def self.tax_filing(doc, file_path)
    return_type = doc.at("ReturnTypeCd")&.text || ''

    data = {
      ein: doc.at("Filer EIN")&.text || '',
      return_type: return_type,
      tax_year: doc.at("TaxYr")&.text || '',
      file_name: File.basename(file_path),
      business_name: doc.at("BusinessName BusinessNameLine1Txt")&.text || '',
      website_url: doc.at("WebsiteAddressTxt")&.text || '',
      mission_description: (doc.at("ActivityOrMissionDesc") || doc.at("MissionDesc"))&.text || '',

      **extract_financial_data(doc, return_type)
    }

    return data
  end

  def self.extract_financial_data(doc, form_type)
    case form_type
    when '990'
      {
        total_revenue: doc.at('CYTotalRevenueAmt')&.text&.to_f || 0,
        total_expenses: doc.at('CYTotalExpensesAmt')&.text&.to_f || 0,
        total_assets: doc.at('TotalAssetsEOYAmt')&.text&.to_f || 0,
        employee_count: doc.at('TotalEmployeeCnt')&.text&.to_i || doc.at('EmployeeCnt')&.text&.to_i || 0,

        # Previous year data for deltas
        py_total_revenue: doc.at('PYTotalRevenueAmt')&.text&.to_f || 0,
        py_total_expenses: doc.at('PYTotalExpensesAmt')&.text&.to_f || 0,
        py_total_assets: doc.at('TotalAssetsBOYAmt')&.text&.to_f || 0,
        py_employee_count: nil # Not available in 990 forms
      }

    when '990EZ'
      {
        total_revenue: doc.at('TotalRevenueAmt')&.text&.to_f || 0,
        total_expenses: doc.at('TotalExpensesAmt')&.text&.to_f || 0,
        total_assets: doc.at('Form990TotalAssetsGrp EOYAmt')&.text&.to_f || 0,
        employee_count: doc.at('OtherEmployeePaidOver100kCnt')&.text&.to_i || 0,

        # Previous year data from BOY
        py_total_revenue: nil, # Not directly available
        py_total_expenses: nil, # Not directly available
        py_total_assets: doc.at('Form990TotalAssetsGrp BOYAmt')&.text&.to_f || 0,
        py_employee_count: nil # Not available
      }

    when '990PF'
      {
        total_revenue: doc.at('AnalysisOfRevenueAndExpenses TotalRevAndExpnssAmt')&.text&.to_f || 0,
        total_expenses: doc.at('AnalysisOfRevenueAndExpenses TotalExpensesRevAndExpnssAmt')&.text&.to_f || 0,
        total_assets: doc.at('Form990PFBalanceSheetsGrp TotalAssetsEOYAmt')&.text&.to_f || 0,
        employee_count: nil, # Not typically tracked for private foundations

        # Previous year data from BOY
        py_total_revenue: nil, # Not directly available
        py_total_expenses: nil, # Not directly available
        py_total_assets: doc.at('Form990PFBalanceSheetsGrp TotalAssetsBOYAmt')&.text&.to_f || 0,
        py_employee_count: nil # Not available
      }

    else
      raise "Unsupported form type: #{form_type}"
    end
  end
end
