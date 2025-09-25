class SwitchSmtpPasswordToPlain < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:settings, :smtp_password_ciphertext)
      # Renomeia a coluna usada pelo Active Record Encryption
      rename_column :settings, :smtp_password_ciphertext, :smtp_password
    else
      # Se já tiver sido removida, garante que a coluna exista
      add_column :settings, :smtp_password, :string
    end
  end
end
