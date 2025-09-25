require "application_system_test_case"

class PrestadorServicosTest < ApplicationSystemTestCase
  setup do
    @prestador_servico = prestador_servicos(:one)
  end

  test "visiting the index" do
    visit prestador_servicos_url
    assert_selector "h1", text: "Prestador servicos"
  end

  test "should create prestador servico" do
    visit prestador_servicos_url
    click_on "New prestador servico"

    fill_in "Bloqueado", with: @prestador_servico.bloqueado
    fill_in "Cnpj", with: @prestador_servico.cnpj
    fill_in "Cor", with: @prestador_servico.cor
    fill_in "Cpf", with: @prestador_servico.cpf
    fill_in "Email", with: @prestador_servico.email
    fill_in "Fabricante", with: @prestador_servico.fabricante
    fill_in "Fone1", with: @prestador_servico.fone1
    fill_in "Fone2", with: @prestador_servico.fone2
    fill_in "Idoso ou pne", with: @prestador_servico.idoso_ou_pne
    fill_in "Modelo", with: @prestador_servico.modelo
    fill_in "Nome", with: @prestador_servico.nome
    fill_in "Nome fantasia", with: @prestador_servico.nome_fantasia
    fill_in "Observacao", with: @prestador_servico.observacao
    fill_in "Outro documento", with: @prestador_servico.outro_documento
    fill_in "Placa", with: @prestador_servico.placa
    fill_in "Publicado no app", with: @prestador_servico.publicado_no_app
    fill_in "Rg", with: @prestador_servico.rg
    fill_in "Servicos", with: @prestador_servico.servicos
    fill_in "Site", with: @prestador_servico.site
    fill_in "Tipo veiculo", with: @prestador_servico.tipo_veiculo
    fill_in "Whatsapp", with: @prestador_servico.whatsapp
    click_on "Create Prestador servico"

    assert_text "Prestador servico was successfully created"
    click_on "Back"
  end

  test "should update Prestador servico" do
    visit prestador_servico_url(@prestador_servico)
    click_on "Edit this prestador servico", match: :first

    fill_in "Bloqueado", with: @prestador_servico.bloqueado
    fill_in "Cnpj", with: @prestador_servico.cnpj
    fill_in "Cor", with: @prestador_servico.cor
    fill_in "Cpf", with: @prestador_servico.cpf
    fill_in "Email", with: @prestador_servico.email
    fill_in "Fabricante", with: @prestador_servico.fabricante
    fill_in "Fone1", with: @prestador_servico.fone1
    fill_in "Fone2", with: @prestador_servico.fone2
    fill_in "Idoso ou pne", with: @prestador_servico.idoso_ou_pne
    fill_in "Modelo", with: @prestador_servico.modelo
    fill_in "Nome", with: @prestador_servico.nome
    fill_in "Nome fantasia", with: @prestador_servico.nome_fantasia
    fill_in "Observacao", with: @prestador_servico.observacao
    fill_in "Outro documento", with: @prestador_servico.outro_documento
    fill_in "Placa", with: @prestador_servico.placa
    fill_in "Publicado no app", with: @prestador_servico.publicado_no_app
    fill_in "Rg", with: @prestador_servico.rg
    fill_in "Servicos", with: @prestador_servico.servicos
    fill_in "Site", with: @prestador_servico.site
    fill_in "Tipo veiculo", with: @prestador_servico.tipo_veiculo
    fill_in "Whatsapp", with: @prestador_servico.whatsapp
    click_on "Update Prestador servico"

    assert_text "Prestador servico was successfully updated"
    click_on "Back"
  end

  test "should destroy Prestador servico" do
    visit prestador_servico_url(@prestador_servico)
    click_on "Destroy this prestador servico", match: :first

    assert_text "Prestador servico was successfully destroyed"
  end
end
