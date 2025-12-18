# db/migrate/20251218124027_add_release_to_feedbacks.rb
class AddReleaseToFeedbacks < ActiveRecord::Migration[7.1]
  def change
    add_reference :feedbacks, :release, null: true, foreign_key: true
  end
end
