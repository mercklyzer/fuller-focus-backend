class CreateFailedXmlFileProcessingLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :failed_xml_file_processing_logs do |t|
      t.references :xml_batch_log, null: false, foreign_key: true
      t.string :file_path, null: false
      t.text :error_message
      t.text :error_backtrace

      t.timestamps
    end
  end
end
