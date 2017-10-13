SS::Application.routes.draw do
  Gws::Memo::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, on: :collection
  end

  gws 'memo' do
    resources :messages, concerns: :deletion do
      collection do
        # put :set_seen
        # put :set_star
        post :set_seen_all
        post :unset_seen_all
        post :set_star_all
        post :unset_star_all
        put :move
        put :copy
        delete :empty
      end
      member do
        get :toggle_star
        get :download
        get :parts, path: 'parts/:section', format: false, section: /[^\/]+/
        get :header_view
        get :source_view
        put :set_seen
        put :unset_seen
        put :set_star
        put :unset_star
        put :move
        put :copy
        get :reply
        get :reply_all
        get :forward
      end
    end
    resources :comments, path: ':message_id/comments', only: :create
  end
end
