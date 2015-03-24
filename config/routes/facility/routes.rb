SS::Application.routes.draw do

  Facility::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "facility" do
    get "/" => redirect { |p, req| "#{req.path}/searches" }, as: :main
    resources :pages, concerns: :deletion
    resources :nodes, concerns: :deletion
    resources :searches, concerns: :deletion
    resources :services, concerns: :deletion
    resources :locations, concerns: :deletion
    resources :categories, concerns: :deletion

    resources :images, concerns: :deletion
    resources :maps, concerns: :deletion
  end

  node "facility" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "category/(index.:format)" => "public#index", cell: "nodes/category"
    get "service/(index.:format)" => "public#index", cell: "nodes/service"
    get "location/(index.:format)" => "public#index", cell: "nodes/location"

    get "search/(index.:format)" => "public#index", cell: "nodes/search"
    get "search/(map.:format)" => "public#map", cell: "nodes/search"
    get "search/(map-all.:format)" => "public#map_all", cell: "nodes/search"
    get "search/(result.:format)" => "public#result", cell: "nodes/search"
  end

  page "facility" do
    get "image/:filename.:format" => "public#index", cell: "pages/image"
    get "map/:filename.:format" => "public#index", cell: "pages/map"
  end

  namespace "facility", path: ".:site/facility" do
    get "/search_categories" => "search_categories#index"
    get "/search_locations" => "search_locations#index"
    get "/search_services" => "search_services#index"
  end

  namespace "facility", path: ".u:user/facility", module: "facility", servicer: /\d+/ do
    resources :temp_files, concerns: :deletion do
      get :select, on: :member
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
    end
  end
end
