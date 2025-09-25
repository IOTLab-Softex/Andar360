class CreateSolicitacaoParticipantes < ActiveRecord::Migration[7.0]
  def change
    create_table :solicitacao_participantes do |t|
      t.references :participant, null: false, foreign_key: true
      t.string :status, null: false, default: 'pendente'
      t.text :motivo
      t.integer :aprovado_por
      t.datetime :aprovado_em

      t.timestamps
    end
  end
end
