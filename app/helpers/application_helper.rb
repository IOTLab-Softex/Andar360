module ApplicationHelper
   def tela_de_alteracao_de_senha?
    request.fullpath == "/users"
  end


def svg_icon(path, options = {})
  logical = path.to_s.strip.sub(/\A[\/\\]+/, "").tr("\\", "/")
  roots = [
    Rails.root.join("app/assets/images"),
    Rails.root.join("app/javascript/images"),
    Rails.root.join("app/frontend/images")
  ]

  # tenta exato
  direct = roots.map { |r| r.join(logical) }.find { |p| File.exist?(p) }

  file_path =
    direct ||
    begin
      dir  = File.dirname(logical)
      base = File.basename(logical).downcase
      root_with_dir = roots.map { |r| r.join(dir) }.find { |d| Dir.exist?(d) }
      if root_with_dir
        match = Dir.children(root_with_dir).find { |fn| fn.downcase == base }
        match ? root_with_dir.join(match) : nil
      end
    end

  unless file_path && File.exist?(file_path)
    Rails.logger.warn "[svg_icon] NOT FOUND: #{logical}"
    return "(ícone não encontrado)"
  end

  file = File.read(file_path)
  file.gsub!(/\s*(width|height|fill|style)="[^"]*"/, "")
  file.gsub!("<svg", '<svg fill="currentColor"')

  doc = Nokogiri::HTML::DocumentFragment.parse(file)
  svg = doc.at_css("svg")
  svg["style"] ||= "height: 13px; fill: currentColor;"
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
