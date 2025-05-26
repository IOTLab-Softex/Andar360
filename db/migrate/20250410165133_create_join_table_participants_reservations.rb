class CreateJoinTableParticipantsReservations < ActiveRecord::Migration[6.1]
  def change
    create_join_table :participants, :reservations do |t|
      # t.index [:participant_id, :reservation_id]
      # t.index [:reservation_id, :participant_id]
    end
  end
end
