SS::Application.routes.draw do

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, :on => :collection
  end

  concern :copy do
    get :copy, :on => :member
    put :copy, :on => :member
  end

  concern :move do
    get :move, :on => :member
    put :move, :on => :member
  end

  concern :template do
    get :template, :on => :collection
  end

  concern :convert do
    get :convert, :on => :member
    put :convert, :on => :member
  end

  concern :download do
    get :download, :on => :collection
  end

  concern :import do
    get :import, :on => :collection
    post :import, :on => :collection
  end

  concern :index_state do
    get :index_approve, :on => :collection
    get :index_request, :on => :collection
    get :index_ready, :on => :collection
    get :index_closed, :on => :collection
  end

  concern :role do
    get "role/edit" => "groups#role_edit", :on => :member
    put "role" => "groups#role_update", :on => :member
  end

  concern :lock do
    get :lock, :on => :member
    delete :lock, action: :unlock, :on => :member
  end

  namespace "cms", path: ".s:site" do
    get "/" => "main#index", as: :main
    get "preview(:preview_date)/(*path)" => "preview#index", as: :preview
    post "preview(:preview_date)/(*path)" => "preview#form_preview", as: :form_preview
  end

  namespace "cms", path: ".s:site/cms" do
    get "/" => "main#index"
    resource  :site
    resources :roles, concerns: :deletion
    resources :users, concerns: [:deletion, :download, :import]
    resources :groups, concerns: [:deletion, :role, :download, :import]
    resources :members, concerns: :deletion do
      get :download, on: :collection
    end
    resources :contents, path: "contents/(:mod)"

    resources :nodes, concerns: :deletion do
      get :routes, on: :collection
    end

    resources :parts, concerns: :deletion do
      get :routes, on: :collection
    end

    resources :pages, concerns: [:deletion, :copy, :move, :lock]
    resources :layouts, concerns: :deletion
    resources :body_layouts, concerns: :deletion
    resources :editor_templates, concerns: [:deletion, :template]
    resources :theme_templates, concerns: [:deletion, :template]
    resources :notices, concerns: :deletion do
      get :copy, :on => :member
      put :copy, :on => :member
    end
    resources :public_notices, concerns: :deletion do
      get :copy, :on => :member
      put :copy, :on => :member
    end

    resources :files, concerns: [:deletion, :template] do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
    end

    resources :page_searches, concerns: :deletion do
      get :search, on: :member
    end

    resources :postal_codes, concerns: [:deletion, :download, :import]

    get "check_links" => "check_links#index"
    post "check_links" => "check_links#run"
    get "generate_nodes" => "generate_nodes#index"
    post "generate_nodes" => "generate_nodes#run"
    get "generate_pages" => "generate_pages#index"
    post "generate_pages" => "generate_pages#run"
    get "import" => "import#index"
    post "import" => "import#import"
    get "all_contents(.:format)" => "all_contents#index", format: { default: :html }, as: "all_contents"
    get "search_contents/html" => "search_contents/html#index"
    post "search_contents/html" => "search_contents/html#update"
    get "search_contents/pages" => "search_contents/pages#index"
    get "search_contents/:id" => "page_search_contents#show", as: "page_search_contents"

    namespace "apis" do
      get "groups" => "groups#index"
      get "nodes" => "nodes#index"
      get "pages" => "pages#index"
      get "categories" => "categories#index"
      get "contents" => "contents#index"
      get "contents/html" => "contents/html#index"
      get "members" => "members#index"

      resources :files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end
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
    get "import" => "import#index"
    post "import" => "import#import"
    resource :conf, concerns: [:copy, :move] do
      get :delete, :on => :member
    end
    resources :nodes, concerns: :deletion
    resources :pages, concerns: [:deletion, :copy, :move, :lock]
    resources :import_pages, concerns: [:deletion, :copy, :move, :convert, :index_state]
    resources :import_nodes, concerns: [:deletion, :copy, :move]
    resources :parts, concerns: :deletion
    resources :layouts, concerns: :deletion
    resources :archives, only: [:index]
  end

  node "cms" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml"         => "public#rss", cell: "nodes/page", format: "xml"
    get "import_node/(index.:format)" => "public#index", cell: "nodes/import_node"
    get "import_node/rss.xml"         => "public#rss", cell: "nodes/import_node", format: "xml"
    get "archive/:ymd/(index.:format)" => "public#index", cell: "nodes/archive", ymd: /\d+/
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
    get "import_page/:filename.:format" => "public#index", cell: "pages/import_page"
  end

  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
    via: [:get, :post, :put, :patch, :delete], format: true
  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
    via: [:get, :post, :put, :patch, :delete], format: false

  root "cms/public#index", defaults: { format: :html }
end
