# This file configures our Error logging.
Rails.application.config.to_prepare do
  # In the Era schema, the column is ERROR_LOG.ZUSERID:
  NdrError.user_column = :custom_user_column

  # Set ERROR_LOG.CUSTOM_USER_COLUMN to "Bob Jones":
  NdrError.log_parameters = -> { { user_id: 'Bob Jones' } }
end
