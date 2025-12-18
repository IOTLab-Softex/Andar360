class AddIndexToFeedbacksReleaseStatus < ActiveRecord::Migration[7.1]
  def change
    add_index :feedbacks, [:release_id, :status]
  end
end
