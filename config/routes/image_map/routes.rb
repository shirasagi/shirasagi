Rails.application.routes.draw do

  ImageMap::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :change_state do
    put :change_state_all, on: :collection, path: ''
  end

  concern :lock do
    get :lock, on: :member
    delete :lock, action: :unlock, on: :member
  end

  concern :contains_urls do
    get :contains_urls, on: :member
  end

  content "image_map" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :lock, :change_state, :contains_urls]
  end

  node "image_map" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
  end

  page "image_map" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

  part "image_map" do
    get "page" => "public#index", cell: "parts/page"
  end
end
