# app/helpers/visualizacao_helper.rb
module VisualizacaoHelper
def marcar_como_visualizado(tipo, id)
  cookies["#{tipo}-#{id}"] = {
    value: Time.current.to_i,
    expires: 1.year.from_now,
    path: '/'
  }
end

def visualizado_pelo_usuario?(tipo, objeto)
  raw_cookie = cookies["#{tipo}-#{objeto.id}"]
  return false unless raw_cookie.present?

  visualizado_em = Time.at(raw_cookie.to_i)
  visualizado_em >= objeto.updated_at
end



end
