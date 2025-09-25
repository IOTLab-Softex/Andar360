class ChangeDestinatarioToParticipantInEncomendas < ActiveRecord::Migration[7.0]
  def change
    remove_column :encomendas, :destinatario, :string
    add_reference :encomendas, :destinatario, foreign_key: { to_table: :participants }
  end
end
