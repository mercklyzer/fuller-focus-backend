class XmlBatchLog < ApplicationRecord
  belongs_to :extraction
  has_many :failed_xml_file_processing_logs, dependent: :destroy

  def files_failed_count
    failed_xml_file_processing_logs.count
  end
end
