class AddEntregueToEncomendas < ActiveRecord::Migration[8.0]
  def change
    add_column :encomendas, :entregue, :boolean, default: false
    add_column :encomendas, :recebido_por_id, :integer
    add_column :encomendas, :entregue_em, :datetime
    add_index :encomendas, :recebido_por_id
  end
end
