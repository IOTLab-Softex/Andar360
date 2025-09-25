class AddInicioFlagsToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :inicio_notificado_em, :datetime
    add_column :reservations, :pre_inicio_notificado_em, :datetime
  end
end
