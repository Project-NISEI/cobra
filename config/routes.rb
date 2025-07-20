# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#home'

  get :login, to: 'oauth#auth'
  get :logout, to: 'oauth#logout'

  namespace :oauth do
    get :callback
  end

  resources :tournaments do
    resources :players, only: %i[index new create update destroy] do
      get :standings, on: :collection
      get :standings_data, on: :collection
      get :meeting, on: :collection
      get :download_decks, on: :collection
      get :download_streaming, on: :collection
      patch :drop, on: :member
      patch :reinstate, on: :member
      patch :lock_registration, on: :member
      patch :unlock_registration, on: :member
      get :registration, on: :member
      get :view_decks, on: :member
    end
    resources :rounds, only: %i[index show create edit update destroy] do
      resources :pairings, only: %i[index create destroy] do
        post :report, on: :member
        post :self_report, on: :member
        get :match_slips, on: :collection
        get :view_decks, on: :member
        get :pairing_presets, on: :member
      end
      patch :repair, on: :member
      patch :complete, on: :member
      patch :update_timer, on: :member
      get :view_pairings, on: :collection
      get :pairings_data, on: :collection
    end
    resources :stages, only: %i[create destroy]
    get :info, on: :member
    post :upload_to_abr, on: :member
    get :save_json, on: :member
    get :id_and_faction_data, on: :member
    get :cut_conversion_rates, on: :member
    get :side_win_percentages, on: :member
    post :cut, on: :member
    get :qr, on: :member
    get :registration, on: :member
    get :timer, on: :member
    patch :open_registration, on: :member
    patch :close_registration, on: :member
    patch :lock_player_registrations, on: :member
    patch :unlock_player_registrations, on: :member
    get :shortlink, on: :collection
    get :not_found, on: :collection
    get :my, on: :collection
    get :new_form, on: :collection
    get :edit_form, on: :member
    get :stats, on: :member
    get :new_demo, on: :collection
    get :new_demo_form, on: :collection
    post :create_demo, on: :collection
    get 'type/:type_id', to: 'tournaments#index', on: :collection, as: :tournaments_by_type
  end
  resources :identities, only: [:index]

  get '/error', to: 'errors#show'

  get '/help', to: 'home#help'

  get ':slug', to: 'tournaments#shortlink'

  match '*path', to: redirect('/error'), via: :all
end
