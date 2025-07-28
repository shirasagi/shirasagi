Rails.application.routes.draw do

  Category::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :change_state do
    put :change_state_all, on: :collection, path: ''
  end

  concern :integration do
    get :split, on: :member
    post :split, on: :member
    get :integrate, on: :member
    post :integrate, on: :member
  end

  content "category" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: [:deletion, :change_state, :integration] do
      get :quick_edit, on: :collection
      post :update_inline, on: :collection
    end
    resources :pages do
      get :quick_edit, on: :collection
    end

    get "conf/split" => "node/confs#split"
    post "conf/split" => "node/confs#split"
    get "conf/integrate" => "node/confs#integrate"
    post "conf/integrate" => "node/confs#integrate"
  end

  node "category" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
    get "page/rss-recent.xml" => "public#rss_recent", cell: "nodes/page", format: "xml"
  end

  part "category" do
    get "node" => "public#index", cell: "parts/node"
  end

end
