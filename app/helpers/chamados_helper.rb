module ChamadosHelper
  STATUS_ORDEM = ["Pendente", "Em andamento", "Concluído"].freeze

  def normalizar_status_chamado(status)
    map = {
      "Solicitada" => "Pendente",
      "Finalizada" => "Concluído",
      "Concluida" => "Concluído",
      "Concluido" => "Concluído"
    }
    map[status] || status
  end

  def proximo_status_chamado(status_atual)
    status_atual = normalizar_status_chamado(status_atual.to_s)
    idx = STATUS_ORDEM.index(status_atual) || 0
    STATUS_ORDEM[(idx + 1) % STATUS_ORDEM.length]
  end

  def pode_alterar_status_chamado?(chamado, user)
    return false if user.nil?
    return true if user.admin? || user.operador?

    return false unless user.client?
    return false unless user.participant
    eh_solicitante = chamado.solicitante_id.present? && chamado.solicitante_id == user.participant.id
    eh_responsavel = chamado.responsavel.present? && chamado.responsavel == user.participant.name

    if normalizar_status_chamado(chamado.status) == "Concluído"
      return eh_solicitante
    end

    eh_solicitante || eh_responsavel
  end

  def pode_editar_chamado?(chamado, user)
    return false if user.nil?
    return true if user.admin? || user.operador?

    return false unless user.client?
    return false unless user.participant

    chamado.solicitante_id.present? && chamado.solicitante_id == user.participant.id
  end
end
