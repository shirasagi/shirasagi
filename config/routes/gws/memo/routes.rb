SS::Application.routes.draw do
  Gws::Memo::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete :destroy_all, on: :collection, path: ''
  end

  gws 'memo' do
    get '/' => redirect { |p, req| "#{req.path}/messages/INBOX" }, as: :main

    resources :messages, concerns: :deletion, path: 'messages/:folder',
              folder: /[^\/]+/, defaults: { folder: 'INBOX' } do
      collection do
        post :trash_all
        post :set_seen_all
        post :unset_seen_all
        post :set_star_all
        post :unset_star_all
        post :move_all
        put :move
        get :recent
        get :latest
      end
      member do
        get :trash
        post :toggle_star
        get :download
        get :parts, path: 'parts/:section', format: false, section: /[^\/]+/
        get :reply
        get :reply_all
        get :forward
        get :ref
        get :print
        put :send_mdn
        put :ignore_mdn
      end
    end

    resources :notices, concerns: :deletion, only: [:index, :show, :destroy] do
      get :recent, on: :collection
      get :latest, on: :collection
    end

    resource :notice_user_settings, only: [:show, :edit, :update]

    resources :comments, path: ':message_id/comments', only: [:create, :destroy]

    namespace "apis" do
      get "shared_addresses" => "shared_addresses#index"
      get "personal_addresses" => "personal_addresses#index"
      get "messages" => "messages#index"
      get "categories" => "categories#index"
    end

    scope '/management' do
      get '/' => redirect { |p, req| "#{req.path}/folders" }, as: :management_main
      resources :folders, concerns: :deletion
      resources :filters, concerns: :deletion
      resources :signatures, concerns: :deletion
      resources :templates, concerns: :deletion
      resource :forwards, only: [:show, :edit, :update]
      resources :lists, concerns: :deletion do
        resources :messages, controller: 'list_messages', concerns: :deletion do
          match :publish, on: :member, via: %i[get post]
          get :seen, on: :member
        end
      end
      resources :categories, concerns: :deletion

      get 'export_messages' => 'export_messages#index'
      put 'export_messages' => 'export_messages#export'
      get 'start_export_messages' => 'export_messages#start_export'
      get 'import_messages' => 'import_messages#index'
      put 'import_messages' => 'import_messages#import'
    end
  end
end
