class CreateJoinTableMeetingsParticipants < ActiveRecord::Migration[8.0]
  def change
    create_join_table :meetings, :participants do |t|
      # t.index [:meeting_id, :participant_id]
      # t.index [:participant_id, :meeting_id]
    end
  end
end
