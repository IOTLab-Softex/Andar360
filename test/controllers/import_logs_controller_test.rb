require "test_helper"

class ImportLogsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get import_logs_index_url
    assert_response :success
  end
end
