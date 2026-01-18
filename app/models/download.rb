class Download < ApplicationRecord
  has_one :extraction, dependent: :destroy

  validates :url, presence: true, uniqueness: true

  STATUSES = %w[pending processing success failed].freeze
  validates :status, inclusion: { in: STATUSES }
end
