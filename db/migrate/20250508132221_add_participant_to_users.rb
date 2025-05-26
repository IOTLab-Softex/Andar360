class AddParticipantToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :participant, null: true, foreign_key: true

  end
end
