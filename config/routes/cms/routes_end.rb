Rails.application.routes.draw do

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :move do
    get :move, on: :member
    put :move, on: :member
  end

  concern :template do
    get :template, on: :collection
  end

  concern :convert do
    get :convert, on: :member
    put :convert, on: :member
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :command do
    get :command, on: :member
    post :command, on: :member
  end

  concern :index_state do
    get :index_approve, on: :collection
    get :index_request, on: :collection
    get :index_ready, on: :collection
    get :index_closed, on: :collection
  end

  concern :index_state_deletion do
    delete "index_:state", action: :destroy_all, on: :collection, state: /approve|request|ready|closed/
  end

  concern :contains_urls do
    get :contains_urls, on: :member
  end

  concern :role do
    get "role/edit" => "groups#role_edit", on: :member
    put "role" => "groups#role_update", on: :member
  end

  concern :lock do
    get :lock, on: :member
    delete :lock, action: :unlock, on: :member
  end

  namespace "cms", path: ".s:site" do
    get "/" => "main#index", as: :main
    match "logout" => "login#logout", as: :logout, via: [:get]
    match "login" => "login#login", as: :login, via: [:get, :post]
    get "preview(:preview_date)/(*path)" => "preview#index", as: :preview
    post "preview(:preview_date)/(*path)" => "preview#form_preview", as: :form_preview, format: false
  end

  namespace "cms", path: ".s:site/cms" do
    get "/" => "main#index"
    resource :site
    resources :roles, concerns: [:deletion, :download, :import]
    resources :users, concerns: [:deletion, :download, :import] do
      post :lock_all, on: :collection
      post :unlock_all, on: :collection
    end
    resources :groups, concerns: [:deletion, :role, :download, :import]
    resources :members, concerns: [:deletion, :download] do
      get :verify, on: :member
      post :verify, on: :member
    end
    resources :contents, path: "contents/(:mod)"

    resources :nodes, concerns: [:deletion, :command] do
      get :routes, on: :collection
    end

    resources :parts, concerns: :deletion do
      get :routes, on: :collection
    end

    resources :pages, concerns: [:deletion, :copy, :move, :command, :lock, :contains_urls]
    resources :layouts, concerns: :deletion
    resources :body_layouts, concerns: :deletion
    resources :editor_templates, concerns: [:deletion, :template]
    resources :loop_settings, concerns: :deletion
    resources :command_settings, concerns: :deletion do
      post :run, on: :member
    end
    resources :theme_templates, concerns: [:deletion, :template]
    resources :source_cleaner_templates, concerns: [:deletion, :template]
    resources :word_dictionaries, concerns: [:deletion, :template]
    resources :forms, concerns: [:deletion] do
      resources :init_columns, concerns: [:deletion]
      resources :columns, concerns: [:deletion]
    end
    resources :notices, concerns: [:deletion, :copy]
    resources :public_notices, concerns: [:deletion, :copy]
    resources :sys_notices, only: [:index, :show]

    resources :files, concerns: [:deletion, :template] do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
      get :resize, on: :member
      post :resize, on: :member
      get :contrast_ratio, on: :collection
    end

    resources :page_searches, concerns: :deletion do
      get :search, on: :member
      delete :search, on: :member, action: :destroy_all_pages
    end

    namespace "translate" do
      get "/" => redirect { |p, req| "#{req.path}/text_caches" }, as: :main
      resources :text_caches, concerns: :deletion
      resources :langs, concerns: [:deletion, :download, :import]
      resource :site_setting
    end

    get "check_links" => "check_links#index"
    post "check_links" => "check_links#run"
    get "generate_nodes" => "generate_nodes#index"
    post "generate_nodes" => "generate_nodes#run"
    get "generate_pages" => "generate_pages#index"
    post "generate_pages" => "generate_pages#run"
    get "import" => "import#import"
    post "import" => "import#import"
    get "command" => "command#command"
    post "command" => "command#command"
    get "all_contents(.:format)" => redirect { |p, req| "#{req.path}/download_all" }, as: "all_contents"
    get "all_contents/download_all(.:format)" => "all_contents#download_all", as: "all_contents_download"
    match "all_contents/import(.:format)" => "all_contents#import", via: [:get, :post], as: "all_contents_import"
    get "search_contents/html" => "search_contents/html#index"
    post "search_contents/html" => "search_contents/html#update"
    match "search_contents/pages" => "search_contents/pages#index", via: [:get, :post]
    match "search_contents/files" => "search_contents/files#index", via: [:get, :post]
    get "search_contents/:id" => "page_search_contents#show", as: "page_search_contents"
    delete "search_contents/pages" => "search_contents/pages#destroy_all"
    get "search_contents/:id/download" => "page_search_contents#download", as: "download_page_search_contents"
    delete "search_contents/:id" => "search_contents/pages#destroy_all_pages"

    resources :check_links_pages, only: [:show, :index]
    resources :check_links_nodes, only: [:show, :index]

    namespace "apis" do
      get "groups" => "groups#index"
      get "nodes" => "nodes#index"
      get "pages" => "pages#index"
      get "pages/routes" => "pages#routes"
      get "categories" => "categories#index"
      get "contents" => "contents#index"
      get "contents/html" => "contents/html#index"
      get "members" => "members#index"
      get "sites" => "sites#index"
      put "reload_site_usages" => "site_usages#reload"
      get "users" => "users#index"
      get "node_tree/:id" => "node_tree#index", as: :node_tree
      get "forms" => "forms#index"
      get "forms/temp_file/:id/select" => "forms#select_temp_file", as: :form_temp_file_select
      get "forms/:id/form" => "forms#form", as: :form
      get "forms/:id/columns/:column_id/new" => "forms#new_column", as: :form_column_new
      match "forms/:id/html" => "forms#html", as: :form_html, via: %i[post put]
      match "forms/:id/link_check" => "forms#link_check", as: :form_link_check, via: %i[post put]
      post "validation" => "validation#validate"

      resources :files, path: ":cid/files", concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
        get :contrast_ratio, on: :collection
      end
      resources :user_files, path: ":cid/user_files", concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
        get :contrast_ratio, on: :collection
      end
      resources :temp_files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
        get :contrast_ratio, on: :collection
      end
      namespace :node, path: "node:cid/cms", cid: /\w+/ do
        resources :temp_files, concerns: :deletion do
          get :select, on: :member
          get :view, on: :member
          get :thumb, on: :member
          get :download, on: :member
          get :contrast_ratio, on: :collection
        end
      end
      resources :content_files, only: [] do
        get :view, on: :member
        get :contrast_ratio, on: :collection
      end
      namespace "opendata_ref" do
        get "datasets:cid" => "datasets#index", as: 'datasets'
      end
      scope "preview(:preview_date)", module: "preview", as: "preview" do
        namespace "inplace_edit" do
          resources :pages, only: %i[edit update] do
            resources :column_values, only: %i[new create edit update destroy] do
              post :move_up, on: :member
              post :move_down, on: :member
              post :move_at, on: :member
              post :link_check, on: :collection
              post :form_check, on: :collection
              post :link_check, on: :member
              post :form_check, on: :member
            end
          end
          resources :forms, only: %i[] do
            get :palette, on: :member
          end
        end

        namespace "workflow" do
          match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: "wizard_approver_setting"
          get "/wizard/:id/reroute" => "wizard#reroute", as: "wizard_reroute"
          post "/wizard/:id/reroute" => "wizard#do_reroute"
          get "/wizard/:id/frame" => "wizard#frame", as: "wizard_frame"
          get "/wizard/:id/comment" => "wizard#comment", as: "wizard_comment"
          match "/wizard/:id" => "wizard#index", via: [:get, :post], as: "wizard"
        end

        resources :nodes, param: :cid, only: [] do
          post :publish, on: :member
          get :new_page, on: :member
        end
        resources :pages, only: [] do
          post :publish, on: :member
          post :lock, on: :member
          delete :lock, on: :member, action: :unlock
        end
      end

      namespace "translate" do
        get "langs" => "langs#index"
      end
    end
  end

  namespace "cms", path: ".cms" do
    match "link_check/check" => "link_check#check", via: [:post, :options], as: "link_check"
    match "mobile_size_check/check" => "mobile_size_check#check", via: [:post, :options], as: "mobile_size_check"
  end

  content "cms", name: "node", module: "cms/node" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    get "generate_nodes" => "generate_nodes#index"
    post "generate_nodes" => "generate_nodes#run"
    get "generate_pages" => "generate_pages#index"
    post "generate_pages" => "generate_pages#run"
    get "import" => "import#import"
    post "import" => "import#import"
    get "command" => "command#command"
    post "command" => "command#command"
    get "copy_nodes" => "copy_nodes#index", as: :copy
    post "copy_nodes" => "copy_nodes#run"
    resource :conf, concerns: [:copy, :move, :command] do
      get :delete, on: :member
    end
    resources :max_file_sizes, concerns: :deletion
    resources :nodes, concerns: :deletion
    resources :pages, concerns: [:deletion, :copy, :move, :lock, :command, :contains_urls]
    resources :import_pages, concerns: [:deletion, :convert]
    resources :import_nodes, concerns: [:deletion]
    get "/group_pages" => redirect { |p, req| "#{req.path.sub(/\/group_pages$/, "")}/nodes" }
    resources :parts, concerns: :deletion
    resources :layouts, concerns: :deletion
    resources :archives, only: [:index]
    resources :photo_albums, only: [:index]
    resources :site_searches, only: [:index]
    get "search_contents/:id" => "page_search_contents#show", as: "page_search_contents"
    get "search_contents/:id/download" => "page_search_contents#download", as: "download_page_search_contents"
  end

  node "cms" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
    get "group_page/(index.:format)" => "public#index", cell: "nodes/group_page"
    get "group_page/rss.xml" => "public#rss", cell: "nodes/group_page", format: "xml"
    get "import_node/(index.:format)" => "public#index", cell: "nodes/import_node"
    get "import_node/rss.xml" => "public#rss", cell: "nodes/import_node", format: "xml"
    get "archive/:ymd/(index.:format)" => "public#index", cell: "nodes/archive", ymd: /\d+/
    get "archive" => "public#redirect_to_archive_index", cell: "nodes/archive"
    get "photo_album" => "public#index", cell: "nodes/photo_album"
    get "site_search/(index.:format)" => "public#index", cell: "nodes/site_search"
  end

  part "cms" do
    get "free" => "public#index", cell: "parts/free"
    get "node" => "public#index", cell: "parts/node"
    get "page" => "public#index", cell: "parts/page"
    get "tabs" => "public#index", cell: "parts/tabs"
    get "crumb" => "public#index", cell: "parts/crumb"
    get "sns_share" => "public#index", cell: "parts/sns_share"
    get "calendar_nav" => "public#index", cell: "parts/calendar_nav"
    get "monthly_nav" => "public#index", cell: "parts/monthly_nav"
  end

  page "cms" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
    get "import_page/:filename.:format" => "public#index", cell: "pages/import_page"
  end

  unless Rails.env.development?
    namespace "cms", path: ".s:site" do
      match "*private_path" => "catch_all#index", via: :all
    end
  end

  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
        via: [:get, :post, :put, :patch, :delete], format: true
  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
        via: [:get, :post, :put, :patch, :delete], format: false

  root "cms/public#index", defaults: { format: :html }
end
