Rails.application.routes.draw do
  resources :formulario_cadastros

# config/routes.rb
resources :settings, only: [:index, :edit, :update] do
  member do
    post  :test_mail
    patch :generate_vapid
  end
end

post "ai_agent/chat", to: "ai_agent#chat"
post "ai_agent/speech", to: "ai_agent#speech"



# /settings -> index -> redireciona para /settings/:id/edit
 resources :feedbacks, only: [:index, :show, :create, :update, :destroy] do
    member do
      patch :change_status   # altera status (admin)
      patch :assign_to_me    # atribuir a mim (admin)
      patch :resolve         # marcar como resolvido (admin)
    end
    collection do
      get :mine              # meus feedbacks (do usuário logado)
    end
  end
  get "rooms/:id/rules", to: "rooms#rules", as: :room_rules
# config/routes.rb
resources :formulario_cadastros do
  member do
    post :approve
    post :reject
  end
  collection do
    post :bulk_approve
    post :bulk_reject
  end
end

# config/routes.rb
resources :formulario_cadastros do
  member do
    post :reenviar_para_aprovacao
  end
end

resources :solicitacao_compras do
  member do
    post  :autorizar
    patch :marcar_comprado
    patch :cancelar_compra
    # depois você pode criar :rejeitar aqui também
  end
end


resources :room_items, only: [:index, :new, :create, :edit, :update, :destroy] do
  collection do
    delete :bulk_destroy
    post   :import
    get    :template
  end
end


  resources :prestador_servicos
  resources :items
  get "arquivos_anexos_chamado/destroy"
get 'participants/por_empresa/:id', to: 'participants#por_empresa'


  post "items/:id/registrar_devolucao", to: "items#registrar_devolucao", as: :registrar_devolucao_item
  post "/marcar_todos_como_visualizados", to: "visualizacoes#marcar_todos", as: :marcar_todos_como_visualizados
  post "/visualizacoes/marcar_todos", to: "visualizacoes#marcar_todos"

  resources :checklist_items, only: [:create, :destroy]
  resources :notifications, only: [] do
    post :marcar_como_lida, on: :member
    post :marcar_todas_como_lidas, on: :collection
    
  end
  resources :encomendas
  resources :encomendas do
  member do
     patch :entregar
    patch :marcar_entregue
  end
end

  resources :ocorrencias, only: [:create, :update, :destroy] do
    member do
      patch :anexar_arquivo
      delete :remover_arquivo
    end
  end

  resources :items do
    post :registrar_retirada, on: :member
    post :devolver, on: :member
    delete :limpar_historico, on: :member
  end


  resources :manutencao_programadas do
    member do
      patch :anexar_arquivo
      post :adiar
    end
  end

  resources :chamados do
    member do
      patch :anexar_arquivo
      patch :change_status
      post :send_password_recovery_link
    end
    resources :arquivos_anexos_chamado, only: [:destroy]
  end

  resources :manutencao_programadas do
    resources :arquivo_anexos, only: [:destroy]
    patch :anexar_arquivo, on: :member
    member do
      delete "remove_arquivo"
    end
  end

  resources :chamados

  get "chamados/:id/remove_foto", to: "chamados#remove_foto"

  resources :chamados do
    delete "remove_foto", on: :member
  end

  get "sub_grupo_empresas/create"
  get "grupo_empresas/index"
  get "grupo_empresas/new"
  get "grupo_empresas/create"
  get "/sub_grupo_empresas/por_empresa/:grupo_empresa_id", to: "sub_grupo_empresas#por_empresa"

devise_for :users, controllers: {
  registrations: 'users/registrations',
  sessions: 'users/sessions'
}

resource :password_recovery, only: [] do
  post :support_lookup
  post :support_request
  get  :facial_status
  post :facial_lookup
  post :facial_verify
  post :facial_send_reset
end

  get "/dashboard/refresh", to: "dashboard#refresh", as: :refresh_dashboard
  patch "/dashboard/card_order", to: "dashboard#update_card_order", as: :update_dashboard_card_order

  get "import_logs/status", to: "import_logs#status"

  get "import_logs/index"
 
  resources :announcements do
    member { post :mark_viewed }
    collection { post :reorder }
  end

  resources :devices
  resources :room_groups, except: [:show]


  resources :grupo_empresas, only: [:index, :new, :create]
  resources :grupo_empresas
  resources :sub_grupo_empresas, only: [:create, :update, :destroy]

  delete "participants/delete_all", to: "participants#delete_all", as: :delete_all_participants

  resources :import_logs, only: [:index] do
    delete :clear_all, on: :collection
  end

  resources :rooms do
     member do
    get "reservations/json", to: "rooms#reservations_json"
  end
    # Correção: Apenas este já é suficiente para by_room
    get "reservations", to: "reservations#by_room", as: :reservations
    resources :reservations, only: [:index, :new, :create]
    post "open_door", on: :member
      collection do
         delete :bulk_destroy 
    post :import
    get  :template # baixa planilha-modelo
  end
  end

resource :push_subscriptions, only: [:create, :destroy]
get "/push/vapid_public_key", to: "push_subscriptions#vapid_public_key"


# config/routes.rb
resources :releases, only: [:index, :show, :create] do
  member do
    get :export_changelog
  end
end

  resources :participants
resources :participants do
  member do
    post  :resgatar
    post  :solicitar_exclusao
    post  :aprovar_exclusao
    post  :reprovar_exclusao
    patch :block_access
    patch :unblock_access
    get   :check_dependencies
  end
end


resources :participants do
  # ações de membro (precisam do :id)
  post :resgatar,            on: :member
  post :solicitar_exclusao,  on: :member
  post :aprovar_exclusao,    on: :member
  post :reprovar_exclusao,   on: :member
end

  resources :reservations, only: [:new, :show, :edit, :update, :destroy] do
    member do
      get :status
      delete :cancel
    end
  end
  resources :reservations
  get "/camera", to: "participants#camera"
  root "dashboard#index"
  get "dashboard/index"
  get "dashboard", to: "dashboard#index", as: :dashboard

  get "up" => "rails/health#show", as: :rails_health_check
end
