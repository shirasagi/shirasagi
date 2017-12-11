SS::Application.routes.draw do
  Gws::Circular::Initializer

  concern :posts do
    get :disable, on: :member
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
    post :download, on: :collection
    post :set_seen, on: :member
    post :unset_seen, on: :member
    post :toggle_seen, on: :member
    post :set_seen_all, on: :collection
    post :unset_seen_all, on: :collection

    resources :comments do
      get :delete, on: :member
    end
  end

  gws 'circular' do
    resources :posts, concerns: [:posts] do
      delete action: :disable_all, on: :collection
    end

    resources :trashes, concerns: [:posts] do
      get :recover, on: :member
      get :active, on: :member
      post :active_all, on: :collection
    end

    scope(path: ':category', as: 'category') do
      resources :posts, concerns: [:posts]
      resources :trashes, concerns: [:posts] do
        get :recover, on: :member
        get :active, on: :member
        post :active_all, on: :collection
      end
    end

    resources :categories do
      get :delete, on: :member
      delete action: :destroy_all, on: :collection
    end

    namespace 'apis' do
      get 'categories' => 'categories#index'
    end
  end
end
