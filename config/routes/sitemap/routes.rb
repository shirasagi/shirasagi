Rails.application.routes.draw do

  Sitemap::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :crud do
    get :move, on: :member
    put :move, on: :member
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :command do
    get :command, on: :member
    post :command, on: :member
  end

  content "sitemap" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :crud, :command] do
      get :export_urls, on: :collection
    end
  end

  node "sitemap" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
  end

  page "sitemap" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
