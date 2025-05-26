require "test_helper"

class GrupoEmpresasControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get grupo_empresas_index_url
    assert_response :success
  end

  test "should get new" do
    get grupo_empresas_new_url
    assert_response :success
  end

  test "should get create" do
    get grupo_empresas_create_url
    assert_response :success
  end
end
