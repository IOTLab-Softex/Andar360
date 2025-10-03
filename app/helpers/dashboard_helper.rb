# app/helpers/dashboard_helper.rb
module DashboardHelper
  def kpi_card(icon_class, label, value, subtitle = nil, opts = {})
    sparkline = opts[:sparkline]
    url       = opts[:url]

    builder = proc do
      concat(sparkline_svg(sparkline)) if sparkline.present?

      concat content_tag(:div, content_tag(:i, "", class: icon_class), class: "kpi-icon")
      concat content_tag(:div, class: "kpi-meta") {
        safe_join([
          content_tag(:div, label, class: "kpi-label"),
          content_tag(:div, value.to_s, class: "kpi-value"),
          (subtitle.present? ? content_tag(:div, subtitle, class: "kpi-subtitle") : "".html_safe)
        ])
      }
    end

    if url.present?
      # âncora com aparência de card
      link_to url, class: "kpi-card kpi-card--link" do
        builder.call
      end
    else
      content_tag :div, class: "kpi-card" do
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
