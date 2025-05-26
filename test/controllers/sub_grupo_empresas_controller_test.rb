require "test_helper"

class SubGrupoEmpresasControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get sub_grupo_empresas_create_url
    assert_response :success
  end
end
