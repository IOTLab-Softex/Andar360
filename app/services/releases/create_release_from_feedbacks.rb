module Releases
  class CreateReleaseFromFeedbacks
    def initialize(version:, stage:, feedback_ids:)
      @version      = version
      @stage        = stage
      @feedback_ids = feedback_ids
    end

    def call
      ActiveRecord::Base.transaction do
        release = Release.create!(
          version: @version,
          stage: @stage,
          released_at: Time.current
        )

        Feedback.where(id: @feedback_ids).update_all(release_id: release.id)

        release
      end
    end
  end
end
