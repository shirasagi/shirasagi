SS::Application.routes.draw do
  Gws::Circular::Initializer

  concern :posts do
    post :set_seen, on: :member
    post :unset_seen, on: :member
    post :toggle_seen, on: :member
    post :set_seen_all, on: :collection
    post :unset_seen_all, on: :collection

    resources :comments do
      get :delete, on: :member
    end
  end

  concern :admins do
    match :disable, on: :member, via: [:get, :post]
    post :download, on: :collection

    resources :comments do
      get :delete, on: :member
    end
  end

  gws 'circular' do
    resources :posts, concerns: [:posts], except: [:new, :create, :edit, :update, :destroy]

    resources :admins, concerns: [:admins], except: [:destroy] do
      delete action: :disable_all, on: :collection
    end

    resources :trashes, except: [:new, :create, :edit, :update] do
      get :delete, on: :member
      delete action: :destroy_all, on: :collection
      match :active, on: :member, via: [:get, :post]
      post :active_all, on: :collection
    end

    scope(path: ':category', as: 'category') do
      resources :posts, concerns: [:posts]
      resources :admins, concerns: [:admins]
      resources :trashes do
        get :delete, on: :member
        delete action: :destroy_all, on: :collection
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
