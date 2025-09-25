class AddCamposExtrasToRooms < ActiveRecord::Migration[7.0]
  def change
    #remove_column :rooms, :andar, :string
    add_column :rooms, :grupo, :string
    add_column :rooms, :virtual, :boolean, default: false
    add_column :rooms, :alugado, :boolean, default: false
    add_column :rooms, :unidade_vazia, :boolean, default: false
    add_column :rooms, :ativo, :boolean, default: true
    add_column :rooms, :espaco_comun, :boolean, default: false
    add_column :rooms, :categoria, :string
    add_column :rooms, :capacidade, :string
    add_column :rooms, :taxa, :string
    add_column :rooms, :area, :decimal
    add_column :rooms, :matricula, :string
    add_column :rooms, :fracao_ideal, :string
    add_column :rooms, :fracao_extra, :string
    add_column :rooms, :interfone, :string
    add_column :rooms, :vagas_garagem, :string
    add_column :rooms, :empresa_proprietaria, :string
    add_column :rooms, :proprietario_formal, :string
    add_column :rooms, :dados_do_inquilino, :string
    add_column :rooms, :observacao, :text
    add_column :rooms, :regras_de_uso, :string
  end
end
