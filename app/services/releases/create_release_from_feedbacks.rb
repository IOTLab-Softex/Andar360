module Releases
  class CreateReleaseFromFeedbacks
    def call
      old_release = Release.current

      feedbacks = old_release.feedbacks.where(status: :resolvido)

      current_version = Release.file_version
      next_version = VersionBumper.new(current_version, feedbacks).next_version

      # fechar release atual
      old_release.update!(released_at: Time.current)

      # criar nova release
      new_release = Release.create!(
        version: next_version,
        stage: "alpha",
        released_at: nil
      )

      # atualizar arquivo VERSION
      Release.update_file_version(next_version)

      new_release
    end
  end
end
