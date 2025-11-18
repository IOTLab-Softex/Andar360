module RoomsHelper
  def room_photo_tag(photo, max: [1200, 800], **opts)
    return content_tag(:span, "Sem foto", class: "text-muted") unless photo&.attached?

    begin
      # tenta usar Vips/variant
      processed = photo.variant(resize_to_limit: max).processed
      image_tag url_for(processed), **{style: "max-width:640px; height:auto; border-radius:12px; display:block;"}.merge(opts)
    rescue LoadError, NameError => _
      # sem Vips disponível → exibe original (mas a foto aparece)
      image_tag url_for(photo), **{style: "max-width:640px; height:auto; border-radius:12px; display:block;"}.merge(opts)
    end
  end
end
