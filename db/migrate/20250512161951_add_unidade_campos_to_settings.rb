class AddUnidadeCamposToSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :tempo_liberacao_solicitante_unidade, :string
    add_column :settings, :tempo_liberacao_participante_unidade, :string
    add_column :settings, :tempo_verificacao_online_unidade, :string
  end
end
