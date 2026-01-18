require "open-uri"
require "zip"
require "fileutils"
require "securerandom"

class ZipService
  def self.download(url, directory: Rails.root.join("tmp"))
    # Create download record
    download_record = Download.create!(
      url: url,
      filename: "",
      status: "pending"
    )

    begin
      URI.open(url, "rb",
        content_length_proc: ->(total_size) {
          download_record.update(total_size: total_size)
        },
        progress_proc: ->(downloaded_size) {
          download_record.update(
            downloaded_size: downloaded_size,
            status: "processing"
          )
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

  def self.extract(download, destination_directory: nil)
    # Create extraction record
    extraction_record = Extraction.create!(
      download: download,
      status: "pending"
    )

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
end
