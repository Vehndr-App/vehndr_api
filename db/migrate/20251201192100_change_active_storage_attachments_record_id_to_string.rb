class ChangeActiveStorageAttachmentsRecordIdToString < ActiveRecord::Migration[8.0]
  def up
    # Remove invalid attachments where record_id was incorrectly set to 0
    execute "DELETE FROM active_storage_attachments WHERE record_type = 'Vendor' AND record_id = 0"
    execute "DELETE FROM active_storage_attachments WHERE record_type = 'Product' AND record_id = 0"

    # Change record_id column type from bigint to string to support string IDs
    change_column :active_storage_attachments, :record_id, :string
  end

  def down
    # Revert back to bigint (this may cause issues with string IDs)
    change_column :active_storage_attachments, :record_id, :bigint
  end
end
