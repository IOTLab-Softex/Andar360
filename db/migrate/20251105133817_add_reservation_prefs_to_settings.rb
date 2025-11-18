class AddReservationPrefsToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :require_room_rules_ack, :boolean
  end
end
