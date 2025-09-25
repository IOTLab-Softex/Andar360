class CreatePrestadorServicos < ActiveRecord::Migration[8.0]
  def change
    create_table :prestador_servicos do |t|
      t.string :nome
      t.string :publicado_no_app
      t.string :bloqueado
      t.string :cpf
      t.string :rg
      t.string :outro_documento
      t.string :fone1
      t.string :fone2
      t.string :whatsapp
      t.string :email
      t.string :site
      t.string :idoso_ou_pne
      t.string :tipo_veiculo
      t.string :placa
      t.string :fabricante
      t.string :modelo
      t.string :cor
      t.string :nome_fantasia
      t.string :cnpj
      t.text :servicos
      t.text :observacao

      t.timestamps
    end
  end
end
