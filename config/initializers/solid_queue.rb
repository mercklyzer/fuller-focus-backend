# frozen_string_literal: true

# Handle MySQL connection issues with SolidQueue
Rails.application.config.after_initialize do
  # Ensure connections are verified before use
  if defined?(SolidQueue)
    SolidQueue.on_thread_error = ->(error) {
      Rails.logger.error "[SolidQueue] Thread error: #{error.class} - #{error.message}"

      if error.is_a?(ActiveRecord::ConnectionNotEstablished) ||
         error.is_a?(ActiveRecord::StatementInvalid) ||
         error.message.include?("Lost connection") ||
         error.message.include?("MySQL server has gone away")
        Rails.logger.info "[SolidQueue] Reconnecting to database..."
        ActiveRecord::Base.connection_handler.clear_active_connections!
      end
    }
  end
end
