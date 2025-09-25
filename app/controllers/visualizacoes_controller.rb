class VisualizacoesController < ApplicationController
    include VisualizacaoHelper

  def marcar_todos
    tipo = params[:tipo]
    ids = params[:ids] || []

    ids.each do |id|
      cookies["#{tipo}-#{id}"] = {
        value: Time.current.to_i,
        expires: 1.year.from_now,
        path: '/'
      }
    end

    head :ok
  end

  
  
  private

  def visualizar_todos_para(tipo)
    case tipo
    when "manutencao"
      ManutencaoProgramada.where("updated_at >= ?", 24.hours.ago).pluck(:id)
    when "chamado"
      Chamado.where("updated_at >= ?", 24.hours.ago).pluck(:id)
    else
      []
    end
  end


end
