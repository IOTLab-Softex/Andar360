class UpdateSettingsStructure < ActiveRecord::Migration[7.0] # ou sua versão do Rails
  def change
    # Remove as antigas se ainda existirem
    remove_column :settings, :key, :string if column_exists?(:settings, :key)
    remove_column :settings, :value, :string if column_exists?(:settings, :value)

    # Garante que as colunas novas estão lá (apenas se precisar)
    add_column :settings, :backup_dir, :string unless column_exists?(:settings, :backup_dir)
    add_column :settings, :tempo_liberacao_solicitante, :integer unless column_exists?(:settings, :tempo_liberacao_solicitante)
    add_column :settings, :tempo_liberacao_solicitante_unidade, :string unless column_exists?(:settings, :tempo_liberacao_solicitante_unidade)
    add_column :settings, :tempo_liberacao_participante, :integer unless column_exists?(:settings, :tempo_liberacao_participante)
    add_column :settings, :tempo_liberacao_participante_unidade, :string unless column_exists?(:settings, :tempo_liberacao_participante_unidade)
    add_column :settings, :tempo_verificacao_online, :integer unless column_exists?(:settings, :tempo_verificacao_online)
    add_column :settings, :tempo_verificacao_online_unidade, :string unless column_exists?(:settings, :tempo_verificacao_online_unidade)
    add_column :settings, :horario_rotina_importacao, :time unless column_exists?(:settings, :horario_rotina_importacao)
  end
end
