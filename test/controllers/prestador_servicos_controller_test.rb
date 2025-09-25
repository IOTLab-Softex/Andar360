require "test_helper"

class PrestadorServicosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prestador_servico = prestador_servicos(:one)
  end

  test "should get index" do
    get prestador_servicos_url
    assert_response :success
  end

  test "should get new" do
    get new_prestador_servico_url
    assert_response :success
  end

  test "should create prestador_servico" do
    assert_difference("PrestadorServico.count") do
      post prestador_servicos_url, params: { prestador_servico: { bloqueado: @prestador_servico.bloqueado, cnpj: @prestador_servico.cnpj, cor: @prestador_servico.cor, cpf: @prestador_servico.cpf, email: @prestador_servico.email, fabricante: @prestador_servico.fabricante, fone1: @prestador_servico.fone1, fone2: @prestador_servico.fone2, idoso_ou_pne: @prestador_servico.idoso_ou_pne, modelo: @prestador_servico.modelo, nome: @prestador_servico.nome, nome_fantasia: @prestador_servico.nome_fantasia, observacao: @prestador_servico.observacao, outro_documento: @prestador_servico.outro_documento, placa: @prestador_servico.placa, publicado_no_app: @prestador_servico.publicado_no_app, rg: @prestador_servico.rg, servicos: @prestador_servico.servicos, site: @prestador_servico.site, tipo_veiculo: @prestador_servico.tipo_veiculo, whatsapp: @prestador_servico.whatsapp } }
    end

    assert_redirected_to prestador_servico_url(PrestadorServico.last)
  end

  test "should show prestador_servico" do
    get prestador_servico_url(@prestador_servico)
    assert_response :success
  end

  test "should get edit" do
    get edit_prestador_servico_url(@prestador_servico)
    assert_response :success
  end

  test "should update prestador_servico" do
    patch prestador_servico_url(@prestador_servico), params: { prestador_servico: { bloqueado: @prestador_servico.bloqueado, cnpj: @prestador_servico.cnpj, cor: @prestador_servico.cor, cpf: @prestador_servico.cpf, email: @prestador_servico.email, fabricante: @prestador_servico.fabricante, fone1: @prestador_servico.fone1, fone2: @prestador_servico.fone2, idoso_ou_pne: @prestador_servico.idoso_ou_pne, modelo: @prestador_servico.modelo, nome: @prestador_servico.nome, nome_fantasia: @prestador_servico.nome_fantasia, observacao: @prestador_servico.observacao, outro_documento: @prestador_servico.outro_documento, placa: @prestador_servico.placa, publicado_no_app: @prestador_servico.publicado_no_app, rg: @prestador_servico.rg, servicos: @prestador_servico.servicos, site: @prestador_servico.site, tipo_veiculo: @prestador_servico.tipo_veiculo, whatsapp: @prestador_servico.whatsapp } }
    assert_redirected_to prestador_servico_url(@prestador_servico)
  end

  test "should destroy prestador_servico" do
    assert_difference("PrestadorServico.count", -1) do
      delete prestador_servico_url(@prestador_servico)
    end

    assert_redirected_to prestador_servicos_url
  end
end
