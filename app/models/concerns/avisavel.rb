# frozen_string_literal: true
module Avisavel
  extend ActiveSupport::Concern

  included do
    scope :com_data, -> { where.not(data_prevista: nil) }

    # Registros que estão no período de aviso (hoje entre início do aviso e a data prevista)
    scope :em_aviso, -> {
      where.not(data_prevista: nil).where(<<~SQL)
        (
          (dias_para_aviso IS NOT NULL AND CURRENT_DATE BETWEEN (data_prevista - dias_para_aviso) AND data_prevista)
          OR
          (data_de_aviso IS NOT NULL AND CURRENT_DATE BETWEEN data_de_aviso AND data_prevista)
        )
      SQL
    }
  end

  # Data em que começa o aviso (data_de_aviso prioriza; senão dias_para_aviso)
  def inicio_aviso
    return data_de_aviso if respond_to?(:data_de_aviso) && data_de_aviso.present?
    return (data_prevista - dias_para_aviso.days) if respond_to?(:dias_para_aviso) && dias_para_aviso.present? && data_prevista.present?
    nil
  end

  # Está dentro do período de aviso?
  def dentro_do_periodo_de_aviso?(date = Date.current)
    return false unless data_prevista.present?
    ia = inicio_aviso
    ia && date >= ia && date <= data_prevista
  end

  # É o dia previsto?
  def dia_previsto?(date = Date.current)
    data_prevista.present? && date == data_prevista
  end
end
