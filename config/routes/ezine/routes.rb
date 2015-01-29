SS::Application.routes.draw do

  Ezine::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "ezine" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: :deletion do
      get :delivery_confirmation, on: :member
      get :delivery_test_confirmation, on: :member
      get :sent_logs, on: :member
      get :preview_text, on: :member
      post :delivery, on: :member
      post :delivery_test, on: :member
    end
    resources :members, concerns: :deletion
    resources :test_members, concerns: :deletion
    resources :entries, concerns: :deletion
  end

  node "ezine" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/entry/new/(index.:format)" => "public#new", cell: "nodes/form"
    get "page/entry/update/(index.:format)" => "public#update", cell: "nodes/form"
    get "page/entry/remove/(index.:format)" => "public#remove", cell: "nodes/form"
    post "page/confirm.html" => "public#confirm", cell: "nodes/form"
    get "page/entry/verification/(index.:format)" => "public#verify", cell: "nodes/form"
  end

  page "ezine" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end
end
