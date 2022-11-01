Rails.application.routes.draw do
  Gws::Workload::Initializer

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    post :download_all, on: :collection
  end

  gws 'workload' do
    get '/' => redirect { |p, req| "#{req.path}/-/-/works" }, as: :main

    scope(path: ':year/:category', defaults: { year: '-', category: '-' }) do
      resources :works, concerns: [:download, :soft_deletion], except: [:destroy]
      resources :admins, concerns: [:download, :soft_deletion], except: [:destroy]
      resources :trashes, except: [:new, :create, :edit, :update] do
        get :delete, on: :member
        delete :destroy_all, on: :collection, path: ''
        get :recover, on: :member
        match :undo_delete, on: :member, via: [:get, :post]
      end

      resources :categories, concerns: [:deletion]
      resources :clients, concerns: [:deletion]
      resources :cycles, concerns: [:deletion]
      resources :loads, concerns: [:deletion]
    end
  end
end
