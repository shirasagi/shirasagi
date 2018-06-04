SS::Application.routes.draw do
  Gws::Report::Initializer

  concern :deletion do
    get :delete, on: :member
    #delete action: :destroy_all, on: :collection
  end

  gws 'report' do
    get '/' => redirect { |p, req| "#{req.path}/forms" }, as: :setting

    resources :forms, concerns: :deletion do
      match :publish, on: :member, via: [:get, :post]
      match :depublish, on: :member, via: [:get, :post]
      resources :columns, concerns: :deletion
    end

    resources :categories, concerns: [:deletion]

    scope :files do
      get '/' => redirect { |p, req| "#{req.path}/inbox" }, as: :files_main
      resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
        match :undo_delete, on: :member, via: [:get, :post]
      end
      resources :files, path: ':state', except: [:destroy] do
        get :print, on: :member
        match :publish, on: :member, via: [:get, :post]
        match :depublish, on: :member, via: [:get, :post]
        match :copy, on: :member, via: [:get, :post]
        match :soft_delete, on: :member, via: [:get, :post]
        post :soft_delete_all, on: :collection
      end
      resources :files, path: ':state/:form_id', only: [:new, :create], as: 'form_files'
    end

    namespace 'apis' do
      get 'categories' => 'categories#index'
      get 'files' => 'files#index'
    end
  end
end
