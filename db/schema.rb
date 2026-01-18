# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_18_144917) do
  create_table "downloads", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "url", null: false
    t.string "filename", null: false
    t.string "status", default: "pending", null: false
    t.bigint "downloaded_size", default: 0
    t.bigint "total_size"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_downloads_on_status"
    t.index ["url"], name: "index_downloads_on_url"
  end

  create_table "extractions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "download_id", null: false
    t.string "status", default: "pending", null: false
    t.string "extracted_path"
    t.text "error_message"
    t.integer "extracted_files_count", default: 0
    t.integer "total_files_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["download_id"], name: "index_extractions_on_download_id"
    t.index ["status"], name: "index_extractions_on_status"
  end

  create_table "failed_xml_file_processing_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "xml_batch_log_id", null: false
    t.string "file_path", null: false
    t.text "error_message"
    t.text "error_backtrace"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["xml_batch_log_id"], name: "index_failed_xml_file_processing_logs_on_xml_batch_log_id"
  end

  create_table "tax_filings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "ein", limit: 20, null: false
    t.string "return_type", limit: 10, null: false
    t.integer "tax_year", null: false
    t.string "file_name", null: false
    t.string "business_name", null: false
    t.string "website_url"
    t.text "mission_description"
    t.decimal "total_revenue", precision: 15, scale: 2
    t.decimal "total_expenses", precision: 15, scale: 2
    t.decimal "total_assets", precision: 15, scale: 2
    t.integer "employee_count"
    t.decimal "py_total_revenue", precision: 15, scale: 2
    t.decimal "py_total_expenses", precision: 15, scale: 2
    t.decimal "py_total_assets", precision: 15, scale: 2
    t.integer "py_employee_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "xml_batch_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "extraction_id", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_files_count"
    t.integer "files_processed_count", default: 0, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "error_backtrace"
    t.index ["extraction_id"], name: "index_xml_batch_logs_on_extraction_id"
  end

  add_foreign_key "extractions", "downloads"
  add_foreign_key "failed_xml_file_processing_logs", "xml_batch_logs"
  add_foreign_key "xml_batch_logs", "extractions"
end
