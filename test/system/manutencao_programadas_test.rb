require "application_system_test_case"

class ManutencaoProgramadasTest < ApplicationSystemTestCase
  setup do
    @manutencao_programada = manutencao_programadas(:one)
  end

  test "visiting the index" do
    visit manutencao_programadas_url
    assert_selector "h1", text: "Manutencao programadas"
  end

  test "should create manutencao programada" do
    visit manutencao_programadas_url
    click_on "New manutencao programada"

    fill_in "Categoria", with: @manutencao_programada.categoria
    fill_in "Data prevista", with: @manutencao_programada.data_prevista
    fill_in "Dias para aviso", with: @manutencao_programada.dias_para_aviso
    check "Exibir no app" if @manutencao_programada.exibir_no_app
    fill_in "Local", with: @manutencao_programada.local
    fill_in "Observacao", with: @manutencao_programada.observacao
    fill_in "Periodicidade", with: @manutencao_programada.periodicidade
    fill_in "Responsavel", with: @manutencao_programada.responsavel
    fill_in "Titulo", with: @manutencao_programada.titulo
    click_on "Create Manutencao programada"

    assert_text "Manutencao programada was successfully created"
    click_on "Back"
  end

  test "should update Manutencao programada" do
    visit manutencao_programada_url(@manutencao_programada)
    click_on "Edit this manutencao programada", match: :first

    fill_in "Categoria", with: @manutencao_programada.categoria
    fill_in "Data prevista", with: @manutencao_programada.data_prevista
    fill_in "Dias para aviso", with: @manutencao_programada.dias_para_aviso
    check "Exibir no app" if @manutencao_programada.exibir_no_app
    fill_in "Local", with: @manutencao_programada.local
    fill_in "Observacao", with: @manutencao_programada.observacao
    fill_in "Periodicidade", with: @manutencao_programada.periodicidade
    fill_in "Responsavel", with: @manutencao_programada.responsavel
    fill_in "Titulo", with: @manutencao_programada.titulo
    click_on "Update Manutencao programada"

    assert_text "Manutencao programada was successfully updated"
    click_on "Back"
  end

  test "should destroy Manutencao programada" do
    visit manutencao_programada_url(@manutencao_programada)
    click_on "Destroy this manutencao programada", match: :first

    assert_text "Manutencao programada was successfully destroyed"
  end
end
