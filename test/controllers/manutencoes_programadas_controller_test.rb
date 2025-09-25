require "test_helper"

class ManutencoesProgramadasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get manutencoes_programadas_index_url
    assert_response :success
  end

  test "should get new" do
    get manutencoes_programadas_new_url
    assert_response :success
  end

  test "should get edit" do
    get manutencoes_programadas_edit_url
    assert_response :success
  end

  test "should get show" do
    get manutencoes_programadas_show_url
    assert_response :success
  end
end
