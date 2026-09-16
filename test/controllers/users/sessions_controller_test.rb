require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []
  test "legacy recovery link with a reset token redirects to the password form" do
    get shared_password_recovery_path(reset_password_token: "token-test")

    assert_redirected_to edit_user_password_path(reset_password_token: "token-test")
  end
end
