SS::Application.routes.draw do
  Gws::Workflow::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :workflow do
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
    post :pull_up_update, on: :member
    post :restart_update, on: :member
    match :request_cancel, on: :member, via: [:get, :post]
  end

  gws "workflow" do
    get '/' => redirect { |p, req| "#{req.path}/routes" }, as: :setting
    resources :pages, concerns: [:deletion, :workflow]
    resources :routes, concerns: :deletion
    scope :files do
      get '/' => redirect { |p, req| "#{req.path}/all" }, as: :files_main
      resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
        match :undo_delete, on: :member, via: [:get, :post]
      end
      resources :files, path: ':state', concerns: [:soft_deletion, :workflow], except: [:destroy] do
        get :print, on: :member
        match :copy, on: :member, via: %i[get post]
      end
      resources :files, path: ':state/:form_id', only: [:new, :create], as: 'form_files'
    end
    resources :forms, concerns: :deletion do
      match :publish, on: :member, via: [:get, :post]
      match :depublish, on: :member, via: [:get, :post]
      resources :columns, concerns: :deletion
    end
    get "/search_approvers" => "search_approvers#index"
    match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post]
    get "/wizard/:id/reroute" => "wizard#reroute"
    post "/wizard/:id/reroute" => "wizard#do_reroute"
    match "/wizard/:id" => "wizard#index", via: [:get, :post]
  end
end
