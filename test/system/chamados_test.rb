require "application_system_test_case"

class ChamadosTest < ApplicationSystemTestCase
  setup do
    @chamado = chamados(:one)
  end

  test "visiting the index" do
    visit chamados_url
    assert_selector "h1", text: "Chamados"
  end

  test "should create chamado" do
    visit chamados_url
    click_on "New chamado"

    fill_in "Data resolucao", with: @chamado.data_resolucao
    check "Exibir no app" if @chamado.exibir_no_app
    fill_in "Local", with: @chamado.local
    fill_in "Observacao", with: @chamado.observacao
    fill_in "Os", with: @chamado.os
    fill_in "Prioridade", with: @chamado.prioridade
    fill_in "Responsavel", with: @chamado.responsavel
    fill_in "Status", with: @chamado.status
    fill_in "Titulo", with: @chamado.titulo
    fill_in "Unidade", with: @chamado.unidade
    click_on "Create Chamado"

    assert_text "Chamado was successfully created"
    click_on "Back"
  end

  test "should update Chamado" do
    visit chamado_url(@chamado)
    click_on "Edit this chamado", match: :first

    fill_in "Data resolucao", with: @chamado.data_resolucao
    check "Exibir no app" if @chamado.exibir_no_app
    fill_in "Local", with: @chamado.local
    fill_in "Observacao", with: @chamado.observacao
    fill_in "Os", with: @chamado.os
    fill_in "Prioridade", with: @chamado.prioridade
    fill_in "Responsavel", with: @chamado.responsavel
    fill_in "Status", with: @chamado.status
    fill_in "Titulo", with: @chamado.titulo
    fill_in "Unidade", with: @chamado.unidade
    click_on "Update Chamado"

    assert_text "Chamado was successfully updated"
    click_on "Back"
  end

  test "should destroy Chamado" do
    visit chamado_url(@chamado)
    click_on "Destroy this chamado", match: :first

    assert_text "Chamado was successfully destroyed"
  end
end
