# This file configures our Error logging.
Rails.application.config.to_prepare do
  # In the Era schema, the column is ERROR_LOG.ZUSERID:
  NdrError.user_column = :custom_user_column
end
