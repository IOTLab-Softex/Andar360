class AddTempoChecagemAcessoToSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :tempo_checagem_acesso, :integer
    add_column :settings, :tempo_checagem_acesso_unidade, :string
    add_column :settings, :tempo_checagem_reservas, :integer
    add_column :settings, :tempo_checagem_reservas_unidade, :string
    add_column :settings, :limite_horas_turno_reservas_manha, :time
    add_column :settings, :limite_horas_turno_reservas_tarde, :time
    add_column :settings, :limite_horas_turno_reservas_noite, :time

    remove_column :settings, :tempo_liberacao_solicitante_unidade, :string
    remove_column :settings, :tempo_liberacao_participante_unidade, :string
    remove_column :settings, :tempo_liberacao_solicitante, :integer
    remove_column :settings, :tempo_liberacao_participante, :integer
  end
end
