SS::Application.routes.draw do

  Article::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :move do
    get :move, on: :member
    put :move, on: :member
  end

  concern :lock do
    get :lock, on: :member
    delete :lock, action: :unlock, on: :member
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :opendata_ref do
    post :update_opendata_resources, on: :member
  end

  concern :contain_links do
    get :contain_links, on: :member
  end

  content "article" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    get "generate" => "generate#index"
    post "generate" => "generate#run"
    resources :pages, concerns: [:deletion, :copy, :move, :lock, :download, :import, :opendata_ref, :contain_links]
  end

  content "article" do
    get "index_approve" => "pages#index_approve"
    get "index_request" => "pages#index_request"
    get "index_ready" => "pages#index_ready"
    get "index_closed" => "pages#index_closed"
  end

  node "article" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  part "article" do
    get "page" => "public#index", cell: "parts/page"
  end

  page "article" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
