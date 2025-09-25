require "application_system_test_case"

class EncomendasTest < ApplicationSystemTestCase
  setup do
    @encomenda = encomendas(:one)
  end

  test "visiting the index" do
    visit encomendas_url
    assert_selector "h1", text: "Encomendas"
  end

  test "should create encomenda" do
    visit encomendas_url
    click_on "New encomenda"

    fill_in "Codigo", with: @encomenda.codigo
    fill_in "Destinatario", with: @encomenda.destinatario
    fill_in "Observacao", with: @encomenda.observacao
    fill_in "Remetente", with: @encomenda.remetente
    fill_in "Tamanho", with: @encomenda.tamanho
    fill_in "Tipo", with: @encomenda.tipo
    fill_in "Transportadora", with: @encomenda.transportadora
    fill_in "Unidade", with: @encomenda.unidade
    click_on "Create Encomenda"

    assert_text "Encomenda was successfully created"
    click_on "Back"
  end

  test "should update Encomenda" do
    visit encomenda_url(@encomenda)
    click_on "Edit this encomenda", match: :first

    fill_in "Codigo", with: @encomenda.codigo
    fill_in "Destinatario", with: @encomenda.destinatario
    fill_in "Observacao", with: @encomenda.observacao
    fill_in "Remetente", with: @encomenda.remetente
    fill_in "Tamanho", with: @encomenda.tamanho
    fill_in "Tipo", with: @encomenda.tipo
    fill_in "Transportadora", with: @encomenda.transportadora
    fill_in "Unidade", with: @encomenda.unidade
    click_on "Update Encomenda"

    assert_text "Encomenda was successfully updated"
    click_on "Back"
  end

  test "should destroy Encomenda" do
    visit encomenda_url(@encomenda)
    click_on "Destroy this encomenda", match: :first

    assert_text "Encomenda was successfully destroyed"
  end
end
