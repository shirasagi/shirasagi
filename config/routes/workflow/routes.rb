SS::Application.routes.draw do

  Workflow::Initializer

  concern :deletion do
    get :delete, on: :member
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
  end

  content "workflow" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: :deletion
    get "/wizard/:id/approver_setting" => "wizard#approver_setting"
    post "/wizard/:id/approver_setting" => "wizard#approver_setting"
    get "/wizard/:id" => "wizard#index"
    post "/wizard/:id" => "wizard#index"
  end

  namespace "workflow", path: ".:site/workflow" do
    get "/" => "main#index"
    resources :pages, concerns: :deletion
    # get "/wizard/:id/approver_setting" => "wizard#approver_setting"
    # post "/wizard/:id/approver_setting" => "wizard#approver_setting"
    # get "/wizard/:id" => "wizard#index"
    # post "/wizard/:id" => "wizard#index"
  end

end
