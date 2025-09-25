module ApplicationHelper
   def tela_de_alteracao_de_senha?
    request.fullpath == "/users"
  end

   def svg_icon(path, options = {})
  file_path = Rails.root.join("app/assets/images", path)
  return "(ícone não encontrado)" unless File.exist?(file_path)

  file = File.read(file_path)

  # Remove estilos antigos
  file.gsub!(/\s*(width|height|fill|style)="[^"]*"/, "")
  file.gsub!("<svg", '<svg fill="currentColor"')

  doc = Nokogiri::HTML::DocumentFragment.parse(file)
  svg = doc.at_css("svg")

  # 🔴 Aqui aplica um estilo inline se quiser garantir renderização mesmo sem CSS
  svg["style"] = "height: 13px; fill: currentColor;" unless svg["style"]

  svg["class"] = [svg["class"], options[:class]].compact.join(" ") if options[:class]

  doc.to_html.html_safe
end


# app/helpers/application_helper.rb
def indicador_atualizacao_dot(objeto, id_prefix)
  return unless objeto.atualizada_recentemente? && !visualizado_pelo_usuario?("#{id_prefix}-#{objeto.id}")

  content_tag(:span, "", class: "dot-ativo", title: "Atualizado recentemente")
end
def classe_linha_atualizada(objeto, tipo)
  if objeto.atualizada_recentemente? && !visualizado_pelo_usuario?(tipo, objeto)
    "linha-atualizada"
  end
end

def visualizado_pelo_usuario?(id)
  cookies[id].present?
end

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

end
