class CreateXmlBatchLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :xml_batch_logs do |t|
      t.references :extraction, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.integer :total_files_count
      t.integer :files_processed_count, null: false, default: 0
      t.text :error_message

      t.timestamps
    end
  end
end
