class AddCpfTelefoneToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :cpf, :string
    add_column :participants, :telefone, :string
  end
end
