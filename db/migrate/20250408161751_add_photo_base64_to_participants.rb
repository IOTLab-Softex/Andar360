class AddPhotoBase64ToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :photo_base64, :text
  end
end
