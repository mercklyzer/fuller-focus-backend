class DownloadExtractProcessJob < ApplicationJob
  queue_as :xml_processing

  # Retry on connection failures
  retry_on ActiveRecord::ConnectionNotEstablished, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::StatementInvalid, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::ConnectionFailed, wait: 5.seconds, attempts: 3
  retry_on Mysql2::Error, wait: 5.seconds, attempts: 3

  def perform(url)
    puts "Download started: #{url}"

    # Create download record with fresh connection
    download_record = nil
    with_fresh_connection do
      download_record = Download.create!(
        url: url,
        filename: "",
        status: "pending"
      )
    end

    # Release connection during long download
    ActiveRecord::Base.connection_pool.release_connection
    ZipService.download(download_record)
    puts "Download completed: #{download_record.filename}"

    # Create extraction record with fresh connection
    extraction_record = nil
    with_fresh_connection do
      download_record.reload
      extraction_record = Extraction.create!(
        download: download_record,
        status: "pending"
      )
    end

    # Release connection during extraction
    ActiveRecord::Base.connection_pool.release_connection
    ZipService.extract(extraction_record)

    # Process XML with fresh connection
    with_fresh_connection do
      extraction_record.reload
      XmlService.process(extraction_record)
    end
  end

  private

  def with_fresh_connection(&block)
    ActiveRecord::Base.connection_pool.release_connection
    ActiveRecord::Base.connection.reconnect!
    yield
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end
end
