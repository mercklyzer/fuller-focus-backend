class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.string :name
      t.string :key_digest
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end
  end
end
