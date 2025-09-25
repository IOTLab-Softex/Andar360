# db/migrate/XXXXXXXXXXXXXX_create_feedbacks.rb
class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: true, foreign_key: true

      t.integer :category, null: false, default: 0   # 0:bug, 1:melhoria, 2:ideia, 3:outro
      t.integer :status,   null: false, default: 0   # 0:aberto, 1:em_andamento, 2:resolvido, 3:ignorado
      t.integer :severity, null: false, default: 1   # 0:baixa, 1:media, 2:alta, 3:critica

      t.string  :page_path
      t.text    :page_url
      t.string  :page_title
      t.text    :user_agent
      t.text    :selected_text
      t.text    :message
      t.jsonb   :url_params, default: {}

      t.integer :resolved_by_id
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :feedbacks, :category
    add_index :feedbacks, :status
    add_index :feedbacks, :severity
    add_index :feedbacks, :page_path
    add_index :feedbacks, :resolved_by_id
    add_index :feedbacks, :url_params, using: :gin
  end
end
