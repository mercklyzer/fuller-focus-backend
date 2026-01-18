class CreateExtractions < ActiveRecord::Migration[8.0]
  def change
    create_table :extractions do |t|
      t.references :download, null: false, foreign_key: true
      t.string :status, default: 'pending', null: false
      t.string :extracted_path
      t.text :error_message
      t.integer :extracted_files_count, default: 0
      t.integer :total_files_count

      t.timestamps
    end

    add_index :extractions, :status
  end
end
