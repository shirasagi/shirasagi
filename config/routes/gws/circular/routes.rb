SS::Application.routes.draw do
  Gws::Circular::Initializer

  gws 'circular' do
    resources :posts do
      get :delete, on: :member
      delete action: :destroy_all, on: :collection
      post :download, on: :collection

      get :set_seen, on: :member
      get :unset_seen, on: :member
      get :toggle_seen, on: :member
      post :set_seen_all, on: :collection
      post :unset_seen_all, on: :collection

      resources :comments do
        get :delete, on: :member
      end
    end
  end
end
