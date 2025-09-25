class AddChamadoIdToArquivoAnexos < ActiveRecord::Migration[8.0]
  def change
    add_reference :arquivo_anexos, :chamado, null: true, foreign_key: true
    change_column_null :arquivo_anexos, :manutencao_programada_id, true
  end
end
