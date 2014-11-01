SS::Application.routes.draw do

  Article::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "article" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    get "generate" => "generate#index"
    post "generate" => "generate#run"
    resources :pages, concerns: :deletion
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
