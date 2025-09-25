class AddNoShowNotificadoEmToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :no_show_notificado_em, :datetime
  end
end
