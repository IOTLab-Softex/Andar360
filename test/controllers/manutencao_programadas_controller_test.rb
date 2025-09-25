require "test_helper"

class ManutencaoProgramadasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manutencao_programada = manutencao_programadas(:one)
  end

  test "should get index" do
    get manutencao_programadas_url
    assert_response :success
  end

  test "should get new" do
    get new_manutencao_programada_url
    assert_response :success
  end

  test "should create manutencao_programada" do
    assert_difference("ManutencaoProgramada.count") do
      post manutencao_programadas_url, params: { manutencao_programada: { categoria: @manutencao_programada.categoria, data_prevista: @manutencao_programada.data_prevista, dias_para_aviso: @manutencao_programada.dias_para_aviso, exibir_no_app: @manutencao_programada.exibir_no_app, local: @manutencao_programada.local, observacao: @manutencao_programada.observacao, periodicidade: @manutencao_programada.periodicidade, responsavel: @manutencao_programada.responsavel, titulo: @manutencao_programada.titulo } }
    end

    assert_redirected_to manutencao_programada_url(ManutencaoProgramada.last)
  end

  test "should show manutencao_programada" do
    get manutencao_programada_url(@manutencao_programada)
    assert_response :success
  end

  test "should get edit" do
    get edit_manutencao_programada_url(@manutencao_programada)
    assert_response :success
  end

  test "should update manutencao_programada" do
    patch manutencao_programada_url(@manutencao_programada), params: { manutencao_programada: { categoria: @manutencao_programada.categoria, data_prevista: @manutencao_programada.data_prevista, dias_para_aviso: @manutencao_programada.dias_para_aviso, exibir_no_app: @manutencao_programada.exibir_no_app, local: @manutencao_programada.local, observacao: @manutencao_programada.observacao, periodicidade: @manutencao_programada.periodicidade, responsavel: @manutencao_programada.responsavel, titulo: @manutencao_programada.titulo } }
    assert_redirected_to manutencao_programada_url(@manutencao_programada)
  end

  test "should destroy manutencao_programada" do
    assert_difference("ManutencaoProgramada.count", -1) do
      delete manutencao_programada_url(@manutencao_programada)
    end

    assert_redirected_to manutencao_programadas_url
  end
end
