require "test_helper"

class ArquivosAnexosChamadoControllerTest < ActionDispatch::IntegrationTest
  test "should get destroy" do
    get arquivos_anexos_chamado_destroy_url
    assert_response :success
  end
end
