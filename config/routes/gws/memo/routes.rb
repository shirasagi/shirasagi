SS::Application.routes.draw do
  Gws::Memo::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, on: :collection
  end

  gws 'memo' do
    resources :messages, concerns: :deletion, path: 'messages/:folder',
              folder: /[^\/]+/, defaults: { folder: 'INBOX' } do
      collection do
        post :set_seen_all
        post :unset_seen_all
        post :set_star_all
        post :unset_star_all
        post :move_all
        put :move
      end
      member do
        get :toggle_star
        get :download
        get :parts, path: 'parts/:section', format: false, section: /[^\/]+/
      end
    end
    resources :comments, path: ':message_id/comments', only: :create
    resources :folders, concerns: :deletion
  end
end
