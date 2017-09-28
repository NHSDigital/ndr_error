# Add "custom_user_column" as user_id for NdrError::Log table.
class AddCustomUserColumnToErrorLogs < NdrError.migration_class
  def change
    add_column :error_logs, :custom_user_column, :string
  end
end
