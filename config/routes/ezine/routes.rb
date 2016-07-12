SS::Application.routes.draw do

  Ezine::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  content "ezine" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: :deletion do
      get :delivery_confirmation, on: :member
      get :delivery_test_confirmation, on: :member
      get :sent_logs, on: :member
      post :delivery, on: :member
      post :delivery_test, on: :member
    end
    resources :members, concerns: :deletion do
      get :download, on: :collection
    end
    resources :test_members, concerns: :deletion
    resources :entries, concerns: :deletion
    resources :columns, concerns: :deletion
    resources :backnumbers, concerns: :deletion

    resources :member_pages, module: :member_page, controller: :main, concerns: :deletion do
      get :delivery_confirmation, on: :member
      get :delivery_test_confirmation, on: :member
      get :sent_logs, on: :member
      post :delivery, on: :member
      post :delivery_test, on: :member
      get :members, module: :member_page, controller: :members, action: :index, on: :collection
    end
    resources :category_nodes, concerns: :deletion
  end

  node "ezine" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/add.:format" => "public#add", cell: "nodes/form"
    get "page/update.:format" => "public#update", cell: "nodes/form"
    get "page/delete.:format" => "public#delete", cell: "nodes/form"
    post "page/confirm.:format" => "public#confirm", cell: "nodes/form"
    get "page/verify(.:format)" => "public#verify", cell: "nodes/form"
    get "backnumber/(index.:format)" => "public#index", cell: "nodes/backnumber"

    get "member_page/(index.:format)" => "public#index", cell: "nodes/member_page"

    get "category_node/(index.:format)" => "public#index", cell: "nodes/category_node"
  end

  page "ezine" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end
end
