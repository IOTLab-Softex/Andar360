class ChangelogGenerator
  CATEGORY_TITLES = {
    "bug"      => "Bugs",
    "melhoria" => "Melhorias",
    "ideia"    => "Ideias",
    "outro"    => "Outros"
  }

  def initialize(release)
    @release = release
  end

  def generate
    out = []

    # --- Cabeçalho ---
    formatted_date =
      if @release.released_at.present?
        I18n.l(@release.released_at.to_date)
      else
        "Em desenvolvimento"
      end

    out << "## [#{@release.version}] #{@release.stage} - #{formatted_date}"
    out << ""

    grouped = @release.feedbacks.group_by(&:category)

    # --- Corpo do changelog ---
    grouped.each do |category, items|
      title = CATEGORY_TITLES[category] || category.humanize

      out << "### #{title}"
      out << ""

      items.each do |fb|
        page = fb.page_path.present? ? "**[#{fb.page_path}]** " : ""
        status = fb.status.present? ? " *(Status: #{fb.status.humanize})*" : ""

        out << "- #{page}#{fb.message}#{status}"
      end

      out << ""
    end

    out.join("\n")
  end
end
