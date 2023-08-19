Rails.application.routes.draw do
  root 'home#home'

  get :login, to: 'oauth#auth'
  get :logout, to: 'oauth#logout'

  namespace :oauth do
    get :callback
  end

  resources :tournaments do
    resources :players, only: [:index, :new, :create, :update, :destroy] do
      get :standings, on: :collection
      get :meeting, on: :collection
      get :download_decks, on: :collection
      patch :drop, on: :member
      patch :reinstate, on: :member
      patch :lock_registration, on: :member
      patch :unlock_registration, on: :member
      get :registration, on: :member
    end
    resources :rounds, only: [:index, :show, :create, :edit, :update, :destroy] do
      resources :pairings, only: [:index, :create, :destroy] do
        post :report, on: :member
        get :match_slips, on: :collection
        get :view_decks, on: :member
      end
      patch :repair, on: :member
      patch :complete, on: :member
      patch :update_timer, on: :member
    end
    resources :stages, only: [:create, :destroy]
    post :upload_to_abr, on: :member
    get :save_json, on: :member
    post :cut, on: :member
    get :qr, on: :member
    get :registration, on: :member
    get :timer, on: :member
    patch :open_registration, on: :member
    patch :close_registration, on: :member
    get :shortlink, on: :collection
    get :not_found, on: :collection
    get :my, on: :collection
  end
  resources :identities, only: [:index]

  get '/error', to: 'errors#show'

  get '/help', to: 'home#help'

  get ':slug', to: 'tournaments#shortlink'

  match '*path', to: redirect('/error'), via: :all
end
