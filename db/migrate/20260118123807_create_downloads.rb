class CreateDownloads < ActiveRecord::Migration[8.0]
  def change
    create_table :downloads do |t|
      t.string :url, null: false
      t.string :filename, null: false
      t.string :status, default: 'pending', null: false
      t.bigint :downloaded_size, default: 0
      t.bigint :total_size
      t.text :error_message

      t.timestamps
    end

    add_index :downloads, :url
    add_index :downloads, :status
  end
end
