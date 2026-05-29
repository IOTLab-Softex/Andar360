# app/helpers/dashboard_helper.rb
module DashboardHelper
  DASHBOARD_CARD_IDS = %w[chamados minhas_reservas manutencoes salas espacos].freeze

  def dashboard_available_card_ids_for(user)
    cards = %w[chamados minhas_reservas manutencoes espacos]
    cards.insert(3, "salas") if user&.admin? || user&.role == "operador"
    cards << "encomendas" if user&.admin? || dashboard_subgrupo_permission_enabled?(user, :can_manage_encomendas)
    cards << "objetos" if user&.admin? || dashboard_subgrupo_permission_enabled?(user, :can_manage_items)
    cards << "formularios" if user&.admin? || dashboard_subgrupo_permission_enabled?(user, :can_support_access)
    cards
  end

  def dashboard_subgrupo_permission_enabled?(user, permission)
    subgrupo = user&.participant&.sub_grupo_empresa
    return false unless subgrupo&.respond_to?(permission)

    !!subgrupo.public_send(permission)
  end

  def ordered_dashboard_card_ids_for(user)
    available = dashboard_available_card_ids_for(user)
    return available unless user

    user.normalized_dashboard_card_order(available)
  end

  def hidden_dashboard_card_ids_for(user)
    available = dashboard_available_card_ids_for(user)
    return [] unless user&.respond_to?(:normalized_dashboard_hidden_cards)

    user.normalized_dashboard_hidden_cards(available)
  end

  def kpi_card(icon_class, label, value, subtitle = nil, opts = {})
    sparkline = opts[:sparkline]
    url       = opts[:url]
    tone      = opts[:tone].presence || "blue"
    classes   = ["kpi-card", "kpi-card--#{tone}"]
    classes << "kpi-card--link" if url.present?

    builder = proc do
      concat(sparkline_svg(sparkline)) if sparkline.present?

      concat content_tag(:div, class: "kpi-meta") {
        safe_join([
          content_tag(:div, label, class: "kpi-label"),
          content_tag(:div, value.to_s, class: "kpi-value"),
          (subtitle.present? ? content_tag(:div, subtitle, class: "kpi-subtitle") : "".html_safe)
        ])
      }
      concat content_tag(:div, content_tag(:i, "", class: icon_class), class: "kpi-icon")
    end

    if url.present?
      # âncora com aparência de card
      link_to url, class: classes.join(" ") do
        builder.call
      end
    else
      content_tag :div, class: classes.join(" ") do
        builder.call
      end
    end
  end

  def sparkline_svg(series, width: 240, height: 72, padding: 6)
    return "".html_safe if series.blank?
    max = series.max.to_f
    max = 1.0 if max <= 0
    step = (width - padding * 2).to_f / [series.size - 1, 1].max
    points = series.each_with_index.map do |v, i|
      x = padding + i * step
      y = height - padding - (v.to_f / max) * (height - padding * 2)
      [x.round(1), y.round(1)]
    end
    line_d = "M #{points.first.join(' ')} " + points.drop(1).map { |x,y| "L #{x} #{y}" }.join(' ')
    area_d = "#{line_d} L #{points.last.first} #{height - padding} L #{points.first.first} #{height - padding} Z"

    content_tag :svg, class: "kpi-sparkline", width: width, height: height,
                      viewBox: "0 0 #{width} #{height}", preserveAspectRatio: "none" do
      concat content_tag(:path, nil, d: area_d, class: "kpi-sparkline-area")
      concat content_tag(:path, nil, d: line_d, class: "kpi-sparkline-line")
    end
  end
end
