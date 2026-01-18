class AddErrorBacktraceToXmlBatchLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :xml_batch_logs, :error_backtrace, :text
  end
end
