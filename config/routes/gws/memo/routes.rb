SS::Application.routes.draw do
  Gws::Memo::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, on: :collection
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
        post :forward
      end
      member do
        get :trash
        post :toggle_star
        get :download
        get :parts, path: 'parts/:section', format: false, section: /[^\/]+/
        get :reply
      end
    end
    resources :comments, path: ':message_id/comments', only: [:create, :destroy]
    resource :setting, only: [:show, :edit, :update]

    scope '/management' do
      get '/' => redirect { |p, req| "#{req.path}/folders" }, as: :management_main
      resources :folders, concerns: :deletion
      resources :filters, concerns: :deletion
      resources :signatures, concerns: :deletion
      resource :forwards, only: [:show, :edit, :update]
    end
  end
end
