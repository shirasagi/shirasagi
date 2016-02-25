SS::Application.routes.draw do

  Workflow::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
  end

  concern :branch do
    post :branch_create, on: :member
  end

  content "workflow" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: :deletion
    get "/wizard/:id/approver_setting" => "wizard#approver_setting"
    post "/wizard/:id/approver_setting" => "wizard#approver_setting"
    get "/wizard/:id" => "wizard#index"
    post "/wizard/:id" => "wizard#index"
  end

  namespace "workflow", path: ".s:site/workflow" do
    get "/" => "main#index"
    resources :pages, concerns: [:deletion, :branch]
    get "/search_approvers" => "search_approvers#index"
    resources :routes, concerns: :deletion
    get "/wizard/:id/approver_setting" => "wizard#approver_setting"
    post "/wizard/:id/approver_setting" => "wizard#approver_setting"
    get "/wizard/:id" => "wizard#index"
    post "/wizard/:id" => "wizard#index"
  end

end
