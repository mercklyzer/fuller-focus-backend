require "open-uri"
require "zip"
require "fileutils"
require "securerandom"

class ZipService
  def self.download(download_record, directory: Rails.root.join("tmp"))
    url = download_record.url
    last_update_time = Time.now

    begin
      URI.open(url, "rb",
        content_length_proc: ->(total_size) {
          with_reconnection { download_record.update(total_size: total_size) }
        },
        progress_proc: ->(downloaded_size) {
          # Throttle updates to every 10 seconds to avoid connection timeouts
          if Time.now - last_update_time > 10
            with_reconnection do
              download_record.update(
                downloaded_size: downloaded_size,
                status: "processing"
              )
            end
            last_update_time = Time.now
          end
        }
      ) do |remote_file|
        # Try to get filename from Content-Disposition header, fallback to URL basename
        original_filename =
          if remote_file.meta["content-disposition"]
            remote_file.meta["content-disposition"][/filename="?([^"]+)"?/, 1] || File.basename(URI(url).path)
          else
            File.basename(URI(url).path)
          end

        filename = "#{Time.now.to_i}_#{original_filename}"
        download_record.update(filename: filename)

        destination = directory.join(filename)

        File.open(destination, "wb") do |file|
          IO.copy_stream(remote_file, file)
        end

        # Update final status and size
        download_record.update!(
          status: "success",
          downloaded_size: File.size(destination)
        )

        download_record
      end
    rescue => e
      download_record.update(
        status: "failed",
        error_message: "#{e.class}: #{e.message}"
      )

      nil
    end
  end

  def self.extract(extraction_record, destination_directory: nil)
    download = extraction_record.download

    begin
      # Convert to string to handle Pathname objects
      zip_path = Rails.root.join("tmp").join(download.filename).to_s

      # Default destination is the same directory as the zip file, with _extracted suffix
      destination_directory ||= File.join(
        File.dirname(zip_path),
        "#{File.basename(zip_path, '.*')}_extracted"
      )

      # Ensure destination_directory is absolute
      destination_directory = File.expand_path(destination_directory)

      extraction_record.update!(
        extracted_path: destination_directory,
        status: "processing"
      )

      FileUtils.mkdir_p(destination_directory)

      Zip::File.open(zip_path) do |zip_file|
        # Count total files (excluding directories)
        total_files = zip_file.entries.count { |entry| !entry.name.end_with?('/') }
        extraction_record.update!(total_files_count: total_files)

        extracted_count = 0

        zip_file.each do |entry|
          # Skip directories
          next if entry.name.end_with?('/')

          extract_path = File.join(destination_directory, entry.name)
          FileUtils.mkdir_p(File.dirname(extract_path))

          # Extract using block form to avoid path issues
          File.open(extract_path, 'wb') do |f|
            f.write(entry.get_input_stream.read)
          end

          extracted_count += 1

          # Update progress every 10 files or on last file to avoid excessive DB calls
          if extracted_count % 10 == 0 || extracted_count == total_files
            extraction_record.update_column(:extracted_files_count, extracted_count)
          end
        end
      end

      # Update final status
      extraction_record.update!(
        status: "success",
        extracted_files_count: extraction_record.total_files_count
      )

      extraction_record
    rescue => e
      extraction_record.update(
        status: "failed",
        error_message: "#{e.class}: #{e.message}"
      )

      nil
    end
  end

  def self.download_and_extract(url)
    download_record = download(url)
    extract(download_record)
  end

  def self.with_reconnection
    retries = 0
    begin
      ActiveRecord::Base.connection.reconnect! unless ActiveRecord::Base.connection.active?
      yield
    rescue ActiveRecord::ConnectionNotEstablished,
           ActiveRecord::StatementInvalid,
           Mysql2::Error => e
      retries += 1
      if retries <= 3
        sleep(1)
        ActiveRecord::Base.connection.reconnect!
        retry
      else
        Rails.logger.error "Failed to reconnect after #{retries} attempts: #{e.message}"
        raise
      end
    end
  end
end
