class CreateTaxFilings < ActiveRecord::Migration[8.0]
  def change
    create_table :tax_filings do |t|
      t.string :ein, null: false, limit: 20
      t.string :return_type, null: false, limit: 10
      t.integer :tax_year, null: false
      t.string :file_name, null: false # source XML filename for reference

      # Organization information
      t.string :business_name, null: false
      t.string :website_url
      t.text :mission_description

      # Financial data (current year)
      t.decimal :total_revenue, precision: 15, scale: 2
      t.decimal :total_expenses, precision: 15, scale: 2
      t.decimal :total_assets, precision: 15, scale: 2
      t.integer :employee_count

      # Financial data (previous year)
      t.decimal :py_total_revenue, precision: 15, scale: 2
      t.decimal :py_total_expenses, precision: 15, scale: 2
      t.decimal :py_total_assets, precision: 15, scale: 2
      t.integer :py_employee_count

      t.timestamps
    end
  end
end
