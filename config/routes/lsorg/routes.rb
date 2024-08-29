Rails.application.routes.draw do

  Lsorg::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :import do
    match :import, on: :collection, via: %i[get post]
  end

  content "lsorg" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: [:deletion, :import]
    resources :pages, concerns: [:deletion]
  end

  node "lsorg" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
  end
end
