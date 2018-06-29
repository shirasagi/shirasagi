SS::Application.routes.draw do

  Workflow::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :workflow do
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
    post :pull_up_update, on: :member
    post :restart_update, on: :member
    post :request_cancel, on: :member
  end

  concern :branch do
    post :branch_create, on: :member
  end

  content "workflow" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :workflow]
    match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post]
    get "/wizard/:id/reroute" => "wizard#reroute"
    post "/wizard/:id/reroute" => "wizard#do_reroute"
    match "/wizard/:id" => "wizard#index", via: [:get, :post]
  end

  namespace "workflow", path: ".s:site/workflow" do
    get "/" => "main#index"
    resources :pages, concerns: [:deletion, :workflow, :branch]
    get "/search_approvers" => "search_approvers#index"
    resources :routes, concerns: :deletion
    match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post]
    get "/wizard/:id/reroute" => "wizard#reroute"
    post "/wizard/:id/reroute" => "wizard#do_reroute"
    match "/wizard/:id" => "wizard#index", via: [:get, :post]
  end

end
