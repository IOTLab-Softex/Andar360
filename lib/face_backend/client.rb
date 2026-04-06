require "net/http"
require "json"

module FaceBackend
  class Client
    class ServiceError < StandardError; end

    class << self
      def verify(reference_image_base64:, probe_image_base64:)
        attempts = 0

        begin
          attempts += 1
          FaceBackend::Service.ensure_started!

          uri = URI("#{FaceBackend::Service.base_url}/verify")
          request = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json", "Accept" => "application/json" })
          request.body = {
            reference_image_base64: reference_image_base64,
            probe_image_base64: probe_image_base64
          }.to_json

          response = Net::HTTP.start(uri.host, uri.port, open_timeout: 8, read_timeout: 25) do |http|
            http.request(request)
          end

          payload = JSON.parse(response.body)
          if response.is_a?(Net::HTTPSuccess)
            return {
              matched: payload["matched"],
              confidence: payload["confidence"],
              score: payload["score"],
              distance: payload["distance"],
              debug: payload["debug"],
              message: payload["message"]
            }
          end

          if response.code.to_i == 422
            return {
              matched: false,
              confidence: payload["confidence"],
              score: payload["score"],
              distance: payload["distance"],
              debug: payload["debug"],
              message: payload["message"].presence || "Nao foi possivel validar o rosto com seguranca."
            }
          end

          raise ServiceError, (payload["message"].presence || "Falha na validacao facial do servidor.")
        rescue JSON::ParserError
          raise ServiceError, "O backend facial retornou uma resposta invalida."
        rescue StandardError => e
          raise e if e.is_a?(ServiceError)
          retry if attempts < 3

          raise ServiceError, "Nao foi possivel conectar ao backend facial."
        end
      end
    end
  end
end
