class Extraction < ApplicationRecord
  belongs_to :download
  has_one :xml_batch_log, dependent: :destroy

  STATUSES = %w[pending processing success failed].freeze
  validates :status, inclusion: { in: STATUSES }
end
