Rails.application.routes.draw do
  get "sub_grupo_empresas/create"
  get "grupo_empresas/index"
  get "grupo_empresas/new"
  get "grupo_empresas/create"
  get "/sub_grupo_empresas/por_empresa/:grupo_empresa_id", to: "sub_grupo_empresas#por_empresa"

devise_for :users, controllers: {
  registrations: 'users/registrations'
}


  get "import_logs/index"
  resources :settings
  resources :devices
  resources :import_logs, only: [:index]
  resources :grupo_empresas, only: [:index, :new, :create]
resources :grupo_empresas
resources :sub_grupo_empresas, only: [:create, :destroy]




  resources :rooms do
    # Correção: Apenas este já é suficiente para by_room
    get 'reservations', to: 'reservations#by_room', as: :reservations
    resources :reservations, only: [:index, :new, :create]
    post 'open_door', on: :member
  end
  get 'rooms/:room_id/reservations/json', to: 'reservations#reservations', defaults: { format: :json }

  resources :participants
  
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
