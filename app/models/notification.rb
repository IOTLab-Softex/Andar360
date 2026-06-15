class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notificavel, polymorphic: true

  scope :nao_lidas, -> { where(lida: false) }
  scope :recentes,  -> { order(created_at: :desc) }

  after_commit :send_web_push, on: :create

  def preference_category
    text = "#{titulo} #{corpo}".downcase

    if text.match?(/conclu|finaliz|atendimento/)
      "success"
    elsif text.match?(/tecnico|técnico|caminho|prazo|atras/)
      "warning"
    elsif text.match?(/sistema|atualiza|versao|versão/)
      "system"
    else
      "info"
    end
  end

  private

  def send_web_push
    return unless user.receives_notification_category?(preference_category)

    WebPushService.send_to_user(
      user,
      title: titulo.presence || "Nova notificação",
      body:  corpo.to_s.truncate(120),
      url:   url.presence || default_url # 👈 usa a url do banco, se tiver
    )
  end

  def default_url
    # fallback dinâmico se url estiver em branco
    helpers = Rails.application.routes.url_helpers

    case notificavel
    when Chamado
      helpers.chamado_path(notificavel)
    # when ManutencaoProgramada
    #   helpers.manutencao_programada_path(notificavel)
    else
      "/notifications"
    end
  end
end
