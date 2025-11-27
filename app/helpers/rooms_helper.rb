module RoomsHelper
 def room_photo_tag(photo, max: [1200, 800], **opts)
  return content_tag(:span, "Sem foto", class: "text-muted") unless photo&.attached?

  begin
    # tenta gerar a variante
    processed = photo.variant(resize_to_limit: max).processed
    image_tag url_for(processed), **default_style.merge(opts)

  rescue ActiveStorage::FileNotFoundError, Errno::ENOENT
    # mostra “Sem foto” se o arquivo sumiu
    content_tag(:span, "Foto não encontrada (reenviar)", class: "text-danger")

  rescue LoadError, NameError
    # sem Vips → tenta exibir original
    image_tag url_for(photo), **default_style.merge(opts)
  end
end

private

def default_style
  { style: "max-width:640px; height:auto; border-radius:12px; display:block;" }
end

end
