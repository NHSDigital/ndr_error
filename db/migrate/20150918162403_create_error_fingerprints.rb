# Adds original ERROR_FINGERPRINT table to schema
class CreateErrorFingerprints < NdrError.migration_class
  def change
    create_table :error_fingerprints, id: false do |t|
      t.string :error_fingerprintid, primary_key: true
      t.string :ticket_url, length: 2000
      t.string :status
      t.integer :count

      t.timestamps
    end
  end
end
