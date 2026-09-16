require "test_helper"
require "minitest/mock"

class ApontiTvIntegrationTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @previous_token = ENV["APONTI_TV_INTEGRATION_TOKEN"]
    ENV["APONTI_TV_INTEGRATION_TOKEN"] = "integration-test-token"
    @headers = { "Authorization" => "Bearer integration-test-token" }
    @user = User.new(id: 42, email: "integration@example.test", cpf: "12345678901", password: "test-password", role: "client")
  end

  teardown { ENV["APONTI_TV_INTEGRATION_TOKEN"] = @previous_token }

  test "integration requires service credentials" do
    post "/integrations/aponti_tv/authenticate", params: { login: @user.cpf, password: "test-password" }, as: :json
    assert_response :unauthorized
  end

  test "password changes need a current session proof and clear the temporary flag" do
    @user.force_password_change = true
    User.stub(:find_by, @user) do
      @user.stub(:aponti_tv_access?, true) do
        @user.stub(:with_lock, ->(&block) { block.call }) do
          post "/integrations/aponti_tv/change_password", params: {user_id: @user.id, session_version: "invalid", password: "new-password"}, headers: @headers, as: :json
          assert_response :unauthorized
          version = OpenSSL::HMAC.hexdigest("SHA256", ENV["APONTI_TV_INTEGRATION_TOKEN"], "#{@user.id}:#{@user.encrypted_password}")
          post "/integrations/aponti_tv/change_password", params: {user_id: @user.id, session_version: version, password: "test-password"}, headers: @headers, as: :json
          assert_response :unprocessable_entity
          @user.stub(:update, ->(attributes) { @user.assign_attributes(attributes); true }) do
            post "/integrations/aponti_tv/change_password", params: {user_id: @user.id, session_version: version, password: "new-password", password_confirmation: "new-password"}, headers: @headers, as: :json
            assert_response :success
            refute response.parsed_body["force_password_change"]
            assert @user.valid_password?("new-password")
            refute_equal version, response.parsed_body["session_version"]
          end
        end
      end
    end
  end

  test "password and permission are both mandatory and password resets change session version" do
    User.stub(:find_for_database_authentication, @user) do
      @user.stub(:aponti_tv_access?, true) do
        post "/integrations/aponti_tv/authenticate", params: { login: @user.cpf, password: "wrong" }, headers: @headers, as: :json
        assert_response :unauthorized
        post "/integrations/aponti_tv/authenticate", params: { login: @user.cpf, password: "test-password" }, headers: @headers, as: :json
        assert_response :success
        version = response.parsed_body.fetch("session_version")
        refute response.parsed_body.key?("encrypted_password")
        @user.password = "new-password"
        post "/integrations/aponti_tv/authenticate", params: { login: @user.cpf, password: "new-password" }, headers: @headers, as: :json
        assert_response :success
        refute_equal version, response.parsed_body.fetch("session_version")
      end
      @user.stub(:aponti_tv_access?, false) do
        post "/integrations/aponti_tv/authenticate", params: { login: @user.cpf, password: "new-password" }, headers: @headers, as: :json
        assert_response :unauthorized
      end
    end
  end
end
