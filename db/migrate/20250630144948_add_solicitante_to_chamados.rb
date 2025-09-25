class AddSolicitanteToChamados < ActiveRecord::Migration[8.0]
  def change
    add_column :chamados, :solicitante_nome, :string
    add_reference :chamados, :solicitante, foreign_key: { to_table: :participants }
  end
end
