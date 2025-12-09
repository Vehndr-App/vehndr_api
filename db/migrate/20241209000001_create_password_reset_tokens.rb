class CreatePasswordResetTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :password_reset_tokens, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :token, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :password_reset_tokens, [:user_id, :expires_at]
  end
end

