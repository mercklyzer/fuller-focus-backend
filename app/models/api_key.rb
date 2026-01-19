class ApiKey < ApplicationRecord
  scope :active, -> { where(revoked_at: nil) }

  def self.generate!(name:)
    plaintext_key = SecureRandom.hex(32)

    api_key = create!(
      name: name,
      key_digest: Digest::SHA256.hexdigest(plaintext_key)
    )
    
    plaintext_key
  end

  def self.authenticate(plaintext_key)
    return nil if plaintext_key.blank?

    digest = Digest::SHA256.hexdigest(plaintext_key)
    active.find_by(key_digest: digest)
  end
end
