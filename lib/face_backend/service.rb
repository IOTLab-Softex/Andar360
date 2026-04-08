require "socket"
require "net/http"
require "rbconfig"
require "English"

module FaceBackend
  class Service
    HOST = ENV.fetch("FACE_BACKEND_HOST", "127.0.0.1")
    PORT = ENV.fetch("FACE_BACKEND_PORT", "5127").to_i
    HEALTH_TIMEOUT = 25
    START_MUTEX = Mutex.new

    class << self
      def base_url
        "http://#{HOST}:#{PORT}"
      end

      def healthy?
        uri = URI("#{base_url}/health")
        response = Net::HTTP.start(uri.host, uri.port, open_timeout: 1, read_timeout: 1) do |http|
          http.get(uri.request_uri)
        end
        response.is_a?(Net::HTTPSuccess)
      rescue StandardError
        false
      end

      def ensure_started!
        return true if healthy?

        START_MUTEX.synchronize do
          return true if healthy?

          bootstrap!
          spawn_process!
          wait_until_healthy!
        end
      end

      private

      def bootstrap!
        system_or_raise(py_launcher_path, Rails.root.join("face_backend", "bootstrap.py").to_s)
      end

      def spawn_process!
        stdout_log = Rails.root.join("log", "face_backend.log").to_s
        env = {
          "FACE_BACKEND_HOST" => HOST,
          "FACE_BACKEND_PORT" => PORT.to_s
        }

        Process.spawn(
          env,
          venv_python_path,
          Rails.root.join("face_backend", "app.py").to_s,
          out: [stdout_log, "a"],
          err: [stdout_log, "a"],
          chdir: Rails.root.to_s
        )
      rescue Errno::ENOENT => e
        raise "Nao foi possivel iniciar o backend facial: #{e.message}"
      end

      def wait_until_healthy!
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        until healthy?
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at > HEALTH_TIMEOUT
            raise "O backend facial nao respondeu a tempo."
          end

          sleep 0.5
        end
      end

      def system_or_raise(*command)
        success = system(*command)
        return if success

        exit_status = $CHILD_STATUS&.exitstatus
        command_str = command.join(" ")
        linux_hint = "No Ubuntu/Debian, instale: sudo apt install -y python3.12-venv python3-pip"
        raise "Falha ao preparar o backend facial (exit=#{exit_status}). Comando: #{command_str}. #{linux_hint}"
      end

      def py_launcher_path
        default = windows_host? ? "py" : "python3"
        ENV.fetch("FACE_BACKEND_PY_LAUNCHER", default)
      end

      def venv_python_path
        ENV.fetch(
          "FACE_BACKEND_VENV_PYTHON",
          if windows_host?
            Rails.root.join(".face_backend_venv", "Scripts", "python.exe").to_s
          else
            Rails.root.join(".face_backend_venv", "bin", "python").to_s
          end
        )
      end

      def windows_host?
        /mswin|mingw|cygwin/i.match?(RbConfig::CONFIG["host_os"])
      end
    end
  end
end
