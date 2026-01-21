class DownloadsController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :authenticate_api_key!

  STATUS_MESSAGES = {
    "pending" => "Download is already pending.",
    "processing" => "Download is already processing.",
    "success" => "Download has already been completed."
  }.freeze

  def dataset
    url = params.require(:irsZipUrl)
    # TODO: add a validation to check if URL is a downloadable ZIP.
    existing_download = Download.find_by(url: url)

    if existing_download.nil? || existing_download.status == "failed"
      if existing_download&.status == "failed"
        existing_download.destroy
      end

      return queue_new_download(url, existing_download)
    end

    render_download_response(
      message: STATUS_MESSAGES[existing_download.status],
      download: existing_download,
      url: url
    )
  end

  private

  def queue_new_download(url, existing_download)
    DownloadExtractProcessJob.perform_later(url)
    # binding.pry
    message = if existing_download&.status == "failed"
      "Previous download has failed. Previous error: #{existing_download.error_message}. Triggering a new download."
    else
      "Download has been queued."
    end

    render_download_response(message: message, url: url)
  end

  def render_download_response(message:, url:, download: nil)
    data = { message: message, url: url }

    if download
      data.merge!(
        total_file_size: download.total_size,
        downloaded_size: download.downloaded_size,
        error_message: download.error_message,
        started_at: download.created_at,
        updated_at: download.updated_at,
        status: download.status
      )
    end

    if download.extraction
      data.merge!(
        extracted_files_count: download.extraction.extracted_files_count,
        extracted_total_files_count: download.extraction.total_files_count
      )
    end

    if download.extraction.xml_batch_log
      data.merge!(
        processed_files_count: download.extraction.xml_batch_log.files_processed_count,
        processed_total_files_count: download.extraction.xml_batch_log.total_files_count
      )
    end

    render_json(data)
  end

  def authenticate_api_key!
    key = request.headers["X-API-Key"]

    api_key = ApiKey.authenticate(key)

    if api_key
      api_key.update_column(:last_used_at, Time.current)
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
