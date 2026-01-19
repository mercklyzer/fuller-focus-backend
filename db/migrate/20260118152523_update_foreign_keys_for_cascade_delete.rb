class UpdateForeignKeysForCascadeDelete < ActiveRecord::Migration[8.0]
  def change
    # Update xml_batch_logs foreign key to cascade on delete
    remove_foreign_key :xml_batch_logs, :extractions
    add_foreign_key :xml_batch_logs, :extractions, on_delete: :cascade

    # Update failed_xml_file_processing_logs foreign key to cascade on delete
    remove_foreign_key :failed_xml_file_processing_logs, :xml_batch_logs
    add_foreign_key :failed_xml_file_processing_logs, :xml_batch_logs, on_delete: :cascade
  end
end
