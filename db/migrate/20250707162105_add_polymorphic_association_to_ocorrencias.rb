# db/migrate/xxxxxxxx_add_polymorphic_association_to_ocorrencias.rb
class AddPolymorphicAssociationToOcorrencias < ActiveRecord::Migration[8.0]
  def change
    # Adiciona as duas colunas necessárias para a associação polimórfica
    add_reference :ocorrencia, :ocorrenciavel, polymorphic: true, index: true
    
    # Remove a coluna antiga que só servia para ManutencaoProgramada
    remove_reference :ocorrencia, :manutencao_programada, foreign_key: true
  end
end