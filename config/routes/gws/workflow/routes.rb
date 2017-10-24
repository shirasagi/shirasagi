SS::Application.routes.draw do
  Gws::Workflow::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :workflow do
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
    match :request_cancel, on: :member, via: [:get, :post]
  end

  gws "workflow" do
    get '/' => redirect { |p, req| "#{req.path}/routes" }, as: :setting
    resources :pages, concerns: [:deletion, :workflow]
    resources :routes, concerns: :deletion
    scope :files do
      get '/' => redirect { |p, req| "#{req.path}/all" }, as: :files_main
      resources :files, path: ':state', concerns: [:deletion, :workflow] do
        get :print, on: :member
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
