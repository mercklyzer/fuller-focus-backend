require "open-uri"
require "zip"
require "fileutils"
require "securerandom"

class ZipService
  def self.download(url, directory: Rails.root.join("tmp"))
    URI.open(url, "rb") do |remote_file|
      # Try to get filename from Content-Disposition header, fallback to URL basename
      original_filename =
        if remote_file.meta["content-disposition"]
          remote_file.meta
        else
          File.basename(URI(url).path)
        end

      filename = "#{Time.now.to_i}_#{original_filename}"

      destination = directory.join(filename)

      File.open(destination, "wb") do |file|
        IO.copy_stream(remote_file, file)
      end

      destination
    end
  end

  def self.extract(zip_path, destination_directory: nil)
    # Convert to string to handle Pathname objects
    zip_path = zip_path.to_s

    # Default destination is the same directory as the zip file, with _extracted suffix
    destination_directory ||= File.join(
      File.dirname(zip_path),
      "#{File.basename(zip_path, '.*')}_extracted"
    )

    # Ensure destination_directory is absolute
    destination_directory = File.expand_path(destination_directory)

    FileUtils.mkdir_p(destination_directory)

    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |entry|
        # Skip directories
        next if entry.name.end_with?('/')

        extract_path = File.join(destination_directory, entry.name)
        FileUtils.mkdir_p(File.dirname(extract_path))

        # Extract using block form to avoid path issues
        File.open(extract_path, 'wb') do |f|
          f.write(entry.get_input_stream.read)
        end
      end
    end

    destination_directory
  end

  def self.download_and_extract(url)
    downloaded_zip = download(url)
    extract(downloaded_zip)
  end
end
