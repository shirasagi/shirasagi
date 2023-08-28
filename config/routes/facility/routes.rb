Rails.application.routes.draw do

  Facility::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :change_state do
    put :change_state_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
    get :download_logs, on: :collection
  end

  concern :file_api do
    get :select, on: :member
    get :selected_files, on: :collection
    get :view, on: :member
    get :thumb, on: :member
    get :download, on: :member
  end

  content "facility" do
    get "/" => redirect { |p, req| "#{req.path}/searches" }, as: :main
    resources :pages, concerns: [:deletion, :download, :import, :change_state]
    resources :nodes, concerns: [:deletion, :change_state]
    resources :searches, concerns: [:deletion, :change_state]
    resources :services, concerns: [:deletion, :change_state]
    resources :locations, concerns: [:deletion, :change_state]
    resources :categories, concerns: [:deletion, :change_state]

    resources :images, concerns: :deletion
    resources :maps, concerns: :deletion
    resources :notices, concerns: :deletion
  end

  node "facility" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/notices/(index.:format)" => "public#notices", cell: "nodes/page"
    get "page/notices/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
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
    get "notice/:filename.:format" => "public#index", cell: "pages/notice"
  end

  namespace "facility", path: ".s:site/facility" do
    namespace "apis" do
      get "categories" => "categories#index"
      get "locations" => "locations#index"
      get "services" => "services#index"
    end
  end

  namespace "facility", path: ".u:user/facility", module: "facility", servicer: /\d+/ do
    namespace "apis" do
      resources :temp_files, concerns: [:deletion, :file_api] do
        get :contrast_ratio, on: :collection
      end
    end
  end
end
