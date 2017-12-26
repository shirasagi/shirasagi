SS::Application.routes.draw do
  Gws::Circular::Initializer

  concern :posts do
    post :set_seen, on: :member
    post :unset_seen, on: :member
    post :toggle_seen, on: :member
    post :set_seen_all, on: :collection
    post :unset_seen_all, on: :collection
  end

  concern :admins do
    match :disable, on: :member, via: [:get, :post]
    post :download, on: :collection
  end

  gws 'circular' do
    get '/' => redirect { |p, req| "#{req.path}/~/posts" }, as: :main

    scope(path: ':category') do
      resources :posts, concerns: [:posts], except: [:new, :create, :edit, :update, :destroy]
      resources :admins, concerns: [:admins], except: [:destroy]
      resources :trashes, except: [:new, :create, :edit, :update] do
        get :delete, on: :member
        delete action: :destroy_all, on: :collection
        get :recover, on: :member
        get :active, on: :member
        post :active_all, on: :collection
      end
      resources :comments, path: ':parent/:post_id/comments' do
        get :delete, on: :member
      end
    end

    resources :categories do
      get :delete, on: :member
      delete action: :destroy_all, on: :collection
    end

    namespace 'apis' do
      get 'categories' => 'categories#index'
      get 'article_states/:post_id' => 'article_states#index', as: 'article_states'
    end
  end
end
