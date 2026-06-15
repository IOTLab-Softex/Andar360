require "uri"

module FeedbacksHelper
  def current_host_feedback_url(feedback)
    stored_url = feedback.page_url.to_s
    fallback_path = feedback.page_path.presence || root_path
    current_base = "#{request.protocol}#{request.host_with_port}"

    uri = URI.parse(stored_url)
    path = uri.path.presence || fallback_path
    path = "/#{path}" unless path.start_with?("/")
    query = uri.query.present? ? "?#{uri.query}" : ""
    fragment = uri.fragment.present? ? "##{uri.fragment}" : ""

    "#{current_base}#{path}#{query}#{fragment}"
  rescue URI::InvalidURIError
    "#{current_base}#{fallback_path}"
  end
end
