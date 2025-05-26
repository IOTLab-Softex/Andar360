class AddSentToFacialToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :sent_to_facial, :boolean
  end
end
