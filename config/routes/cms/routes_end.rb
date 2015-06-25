SS::Application.routes.draw do

  concern :deletion do
    get :delete, :on => :member
  end

  concern :crud do
    get :move, :on => :member
    put :move, :on => :member
    get :copy, :on => :member
    put :copy, :on => :member
  end

  concern :template do
    get :template, :on => :collection
  end

  concern :role do
    get "role/edit" => "groups#role_edit", :on => :member
    put "role" => "groups#role_update", :on => :member
  end

  namespace "cms", path: ".:site" do
    get "/" => "main#index", as: :main
    get "preview(:preview_date)/(*path)" => "preview#index", as: :preview
  end

  namespace "cms", path: ".:site/cms" do
    get "/" => "main#index"
    resource  :site, concerns: :deletion
    resources :roles, concerns: :deletion
    resources :users, concerns: :deletion
    resources :groups, concerns: [:deletion, :role]
    resources :members, concerns: :deletion
    resources :contents, path: "contents/(:mod)"

    resources :nodes, concerns: :deletion do
      get :routes, on: :collection
    end

    resources :parts, concerns: :deletion do
      get :routes, on: :collection
    end

    resources :pages, concerns: [:deletion, :crud]
    resources :layouts, concerns: :deletion
    resources :editor_templates, concerns: [:deletion, :template]

    resources :files, concerns: [:deletion, :template] do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
    end

    resources :ajax_files, concerns: :deletion do
      get :select, on: :member
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
    end

    get "check_links" => "check_links#index"
    post "check_links" => "check_links#run"
    get "generate_nodes" => "generate_nodes#index"
    post "generate_nodes" => "generate_nodes#run"
    get "generate_pages" => "generate_pages#index"
    post "generate_pages" => "generate_pages#run"
    get "search_contents/html" => "search_contents/html#index"
    post "search_contents/html" => "search_contents/html#update"
    get "search_contents/pages" => "search_contents/pages#index"

    namespace "apis" do
      get "groups" => "groups#index"
      get "pages" => "pages#index"
      get "categories" => "categories#index"
      get "contents" => "contents#index"
      get "contents/html" => "contents/html#index"
    end
  end

  namespace "cms", path: ".cms" do
    match "link_check/check" => "link_check#check", via: [:post, :options], as: "link_check"
  end

  content "cms", name: "node", module: "cms/node" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    get "generate_nodes" => "generate_nodes#index"
    post "generate_nodes" => "generate_nodes#run"
    get "generate_pages" => "generate_pages#index"
    post "generate_pages" => "generate_pages#run"
    resource :conf, concerns: [:deletion, :crud]
    resources :nodes, concerns: :deletion
    resources :pages, concerns: [:deletion, :crud]
    resources :parts, concerns: :deletion
    resources :layouts, concerns: :deletion
  end

  node "cms" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml"         => "public#rss", cell: "nodes/page", format: "xml"
  end

  part "cms" do
    get "free"  => "public#index", cell: "parts/free"
    get "node"  => "public#index", cell: "parts/node"
    get "page"  => "public#index", cell: "parts/page"
    get "tabs"  => "public#index", cell: "parts/tabs"
    get "crumb" => "public#index", cell: "parts/crumb"
    get "sns_share" => "public#index", cell: "parts/sns_share"
  end

  page "cms" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
    via: [:get, :post, :put, :patch, :delete], format: true
  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
    via: [:get, :post, :put, :patch, :delete], format: false

  root "cms/public#index", defaults: { format: :html }
end
