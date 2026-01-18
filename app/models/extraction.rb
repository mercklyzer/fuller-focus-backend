class Extraction < ApplicationRecord
  belongs_to :download

  STATUSES = %w[pending processing success failed].freeze
  validates :status, inclusion: { in: STATUSES }
end
