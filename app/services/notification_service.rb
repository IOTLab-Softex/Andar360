# frozen_string_literal: true
class NotificationService
  # Cria/atualiza notificação para todos os usuários relevantes
  # only_if_in_period: true => só notifica se o record estiver em período de aviso
  def self.notify_users_for(record, only_if_in_period: true)
    # Precisa expor os métodos do concern
    return unless record.respond_to?(:dentro_do_periodo_de_aviso?)

    return if only_if_in_period && !record.dentro_do_periodo_de_aviso?

    User.includes(:participant).find_each do |user|
      # regra: cliente só se exibir_no_app? (quando existir)
      if user.client? && record.respond_to?(:exibir_no_app?) && !record.exibir_no_app?
        next
      end

      titulo =
        if record.respond_to?(:dia_previsto?) && record.dia_previsto?
          "Manutenção é hoje: #{record.try(:titulo) || record.class.model_name.human}"
        else
          "Manutenção próxima: #{record.try(:titulo) || record.class.model_name.human}"
        end

      corpo =
        if record.respond_to?(:data_prevista) && record.data_prevista.present?
          "A manutenção '#{record.try(:titulo)}' está prevista para #{I18n.l(record.data_prevista)}"
        else
          record.try(:descricao).to_s.truncate(140)
        end

      notif = Notification.find_or_initialize_by(user: user, notificavel: record)
      notif.titulo = titulo
      notif.corpo  = corpo
      notif.lida   = false
      notif.save!
    end
  end
end
