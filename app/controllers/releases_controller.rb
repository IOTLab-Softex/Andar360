# app/controllers/releases_controller.rb
class ReleasesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_release, only: [:show, :export_changelog]

def index
  @releases = Release.order(released_at: :desc)

  current_version = Release.file_version
  feedbacks_resolvidos = Release.current.feedbacks.where(status: :resolvido)

  @next_version =
    VersionBumper.new(current_version, feedbacks_resolvidos).next_version
end


def show
  @changelog = ChangelogGenerator.new(@release).generate
  @feedbacks = @release.feedbacks.order(:category)

  current_version = Release.file_version
  feedbacks = @release.feedbacks.where(status: :resolvido)
  @next_version = VersionBumper.new(current_version, feedbacks).next_version
end


  def create
    feedback_ids = Feedback.resolvidos.sem_release.pluck(:id)

    if feedback_ids.empty?
      redirect_back fallback_location: feedbacks_path,
        alert: "Nenhum feedback resolvido pendente para versionar."
      return
    end

    release = Releases::CreateReleaseFromFeedbacks.new(
      version: params[:version],
      stage: params[:stage]
    ).tap do |service|
      service.instance_variable_set(:@feedback_ids, feedback_ids)
    end.call

    redirect_to release_path(release),
      notice: "Release #{release.version} criada com sucesso 🚀"
  end

  def export_changelog
    changelog = ChangelogGenerator.new(@release).generate

    send_data changelog,
      filename: "CHANGELOG-#{@release.version}.md",
      type: "text/markdown"
  end

  private

  def set_release
    @release = Release.find(params[:id])
  end

  def ensure_admin!
    redirect_to root_path, alert: "Acesso restrito." unless current_user.admin?
  end
end
