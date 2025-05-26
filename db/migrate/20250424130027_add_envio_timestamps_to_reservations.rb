class AddEnvioTimestampsToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :solicitantes_enviados_em, :datetime
    add_column :reservations, :participantes_enviados_em, :datetime
  end
end
