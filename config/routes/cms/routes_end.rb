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
    put :move_confirm, on: :member
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

  concern :file_api do
    get :select, on: :member
    get :selected_files, on: :collection
    get :view, on: :member
    get :thumb, on: :member
    get :download, on: :member
  end

  concern :michecker do
    get :michecker, on: :member
    post :michecker_start, on: :member
    get :michecker_result, on: :member
  end

  concern :change_state do
    put :change_state_all, on: :collection, path: ''
  end

  namespace "cms", path: ".s:site" do
    get "/" => "main#index", as: :main
    get "logout" => "login#logout", as: :logout
    match "login" => "login#login", as: :login, via: [:get, :post]
    get "mfa_login" => "mfa_login#login", as: :mfa_login
    post "otp_login" => "mfa_login#otp_login"
    post "otp_setup" => "mfa_login#otp_setup"
    get "preview(:preview_date)/(*path)" => "preview#index", as: :preview
    post "preview(:preview_date)/(*path)" => "preview#form_preview", as: :form_preview, format: false

    namespace :frames do
      resources :nodes_tree, concerns: [:deletion, :command, :change_state, :import]
      namespace :user_navigation do
        resource :menu, only: %i[show]
      end
    end
  end

  namespace "cms", path: ".s:site/cms" do
    get "/" => "main#index"
    resource :site
    resources :roles, concerns: [:deletion, :download, :import]
    resources :users, concerns: [:deletion, :download, :import] do
      post :lock_all, on: :collection
      post :unlock_all, on: :collection
      post :reset_mfa_otp, on: :member
    end
    resources :groups, concerns: [:deletion, :role, :import] do
      match :download_all, on: :collection, via: %i[get post]
      resources :pages, path: ":contact_id/pages", only: %i[index], controller: "group_pages"
    end
    resources :members, concerns: [:deletion, :download] do
      get :verify, on: :member
      post :verify, on: :member
    end
    resources :contents, path: "contents/(:mod)"

    resources :nodes, concerns: [:deletion, :command, :change_state, :import] do
      get :routes, on: :collection
      match :download, on: :collection, via: %i[get post]
    end

    resources :parts, concerns: :deletion do
      get :routes, on: :collection
    end

    resources :pages, concerns: [:deletion, :copy, :move, :command, :lock, :contains_urls, :michecker, :change_state] do
      post :resume_new, on: :collection
      post :resume_edit, on: :member
      put :publish_all, on: :collection
      put :close_all, on: :collection
    end
    resources :layouts, concerns: :deletion
    resources :body_layouts, concerns: :deletion
    resources :editor_templates, concerns: [:deletion, :template]
    resources :loop_settings, concerns: :deletion
    resources :api_tokens, concerns: :deletion
    resources :command_settings, concerns: :deletion do
      post :run, on: :member
    end
    resources :theme_templates, concerns: [:deletion, :template]
    resources :source_cleaner_templates, concerns: [:deletion, :template]
    namespace 'syntax_checker' do
      get "/" => redirect { |p, req| "#{req.path}/word_dictionaries" }, as: :main
      resources :word_dictionaries, concerns: [:deletion, :template]
      resource :setting, only: %i[show edit update]
      resource :url_scheme, only: %i[show edit update]
    end
    resource :user_profile, only: [:show, :edit, :update] do
      get :edit_password, on: :member
      post :edit_password, on: :member, action: :update_password
    end

    scope module: "form" do
      resources :forms, concerns: [:deletion, :download, :import, :change_state] do
        resources :init_columns, concerns: [:deletion]
        resources :columns, concerns: [:deletion]

        get :column_names, on: :collection
      end
    end

    namespace "form" do
      resources :dbs, concerns: [:deletion] do
        resources :import_logs, only: [:show]
        resources :docs, concerns: [:deletion] do
          match :import, via: [:get, :post], on: :collection
          match :download_all, via: [:get, :post], on: :collection
          match :import_url, via: [:get, :post], on: :collection
        end
      end
    end

    resources :notices, concerns: [:deletion, :copy]
    resources :public_notices, concerns: [:deletion, :copy] do
      get :frame_content, on: :member
    end
    resources :sys_notices, only: [:index, :show] do
      get :frame_content, on: :member
    end

    resources :files, concerns: [:deletion, :template] do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
      get :resize, on: :member
      post :resize, on: :member
      get :contrast_ratio, on: :collection
      get :large_file_upload, on: :collection
    end

    resources :page_searches, concerns: :deletion do
      get :search, on: :member
      delete :search, on: :member, action: :destroy_all_pages
    end

    namespace "translate" do
      get "/" => redirect { |p, req| "#{req.path}/text_caches" }, as: :main
      resources :text_caches, concerns: :deletion
      resources :langs, concerns: [:deletion, :download, :import]
      resources :access_logs, only: [:index, :show] do
        get :download, on: :collection
        post :download, on: :collection
      end
      resource :site_setting
    end

    namespace "sns_post" do
      resources :logs, only: [:index, :show, :destroy], concerns: [:deletion]
    end

    namespace "source_cleaner" do
      get "/" => redirect { |p, req| "#{req.path}/site_setting" }, as: :main
      resource :site_setting
    end

    namespace "line" do
      # messages
      resources :messages, concerns: :deletion do
        get :deliver, on: :member
        post :deliver, on: :member
        get :test_deliver, on: :member
        post :test_deliver, on: :member
        get :copy, on: :member
        put :copy, on: :member
        resources :templates, path: "template/:type/templates", defaults: { type: '-' }, concerns: :deletion do
          get :select_type, on: :collection
        end
        resources :deliver_plans, concerns: :deletion
      end
      resources :test_members, concerns: :deletion
      resources :deliver_logs, only: [:index, :show, :destroy], concerns: [:deletion]
      resources :deliver_conditions, concerns: :deletion
      resources :deliver_categories, concerns: :deletion do
        resources :categories, concerns: :deletion, controller: "deliver_category/categories"
      end

      # statistics
      resources :statistics, concerns: [:deletion, :download]

      # mail hanlders
      resources :mail_handlers, concerns: :deletion

      # services
      namespace "richmenu" do
        resources :groups, concerns: :deletion do
          get :apply, on: :collection
          post :apply, on: :collection
          resources :menus, concerns: :deletion do
            get :crop, on: :member
            put :crop, on: :member
          end
        end
      end
      namespace "service" do
        resources :groups, concerns: :deletion do
          resources :hooks, path: "hook/:type/hooks", defaults: { type: '-' }, concerns: :deletion do
            get :crop, on: :member
            put :crop, on: :member
            namespace "facility_search" do
              resources :categories, concerns: :deletion
            end
          end
        end
      end
      resources :event_sessions, only: [:index, :show, :destroy], concerns: :deletion
    end

    get "generate_nodes" => "generate_nodes#index"
    get "generate_nodes/segment/:segment" => "generate_nodes#index", as: :segment_generate_nodes
    post "generate_nodes" => "generate_nodes#run"
    get "generate_nodes/download_logs" => "generate_nodes#download_logs"
    post "generate_nodes/segment/:segment" => "generate_nodes#run"
    get "generate_pages" => "generate_pages#index"
    get "generate_pages/segment/:segment" => "generate_pages#index", as: :segment_generate_pages
    post "generate_pages" => "generate_pages#run"
    get "generate_pages/download_logs" => "generate_pages#download_logs"
    post "generate_pages/segment/:segment" => "generate_pages#run"
    namespace "generation_report", path: "generation_report" do
      get "/" => redirect { |p, req| "#{req.path}/nodes/titles" }, as: :main
      get "/nodes" => redirect { |p, req| "#{req.path}/titles" }, as: :nodes
      get "/pages" => redirect { |p, req| "#{req.path}/titles" }, as: :pages
    end
    namespace "generation_report", path: "generation_report/:type" do
      resources :titles, only: %i[index new create destroy], concerns: :deletion
      resources :histories, path: "titles/:title/histories", only: %i[index show] do
        match :download_all, on: :collection, via: %i[get post]
      end
      resources :aggregations, path: "titles/:title/aggregations", only: %i[index] do
        match :download_all, on: :collection, via: %i[get post]
      end
    end
    get "import" => "import#import"
    post "import" => "import#import"
    get "import/download_logs" => "import#download_logs"
    get "command" => "command#command"
    post "command" => "command#command"
    get "all_contents(.:format)" => redirect { |p, req| "#{req.path}/download_all" }, as: "all_contents"
    get "all_contents/download_all(.:format)" => "all_contents#download_all", as: "all_contents_download"
    match "all_contents/import(.:format)" => "all_contents#import", via: [:get, :post], as: "all_contents_import"
    get "all_contents/sampling_all(.:format)" => "all_contents#sampling_all", as: "all_contents_sampling"
    get "search_contents/html" => "search_contents/html#index"
    post "search_contents/html" => "search_contents/html#update"
    match "search_contents/pages" => "search_contents/pages#index", via: [:get, :post]
    delete "search_contents/pages" => "search_contents/pages#destroy_all"
    get "search_contents/files" => "search_contents/files#index"
    get "search_contents/sitemap" => "search_contents/sitemap#index"
    get "search_contents/sitemap/download_all(.:format)" => "search_contents/sitemap#download_all", as: "folder_csv_download"
    get "search_contents/:id" => "page_search_contents#show", as: "page_search_contents"
    get "search_contents/:id/download" => "page_search_contents#download", as: "download_page_search_contents"
    delete "search_contents/:id" => "page_search_contents#destroy_all"
    resource :generate_lock

    get "check_links" => redirect { |p, req| "#{req.path}/reports" }, as: :check_links
    namespace "check_links" do
      get "run" => "run#index"
      post "run" => "run#run"
      resources :reports, concerns: [:deletion], only: [:show, :index] do
        resources :pages, only: [:show, :index] do
          get :download, on: :collection
        end
        resources :nodes, only: [:show, :index] do
          get :download, on: :collection
        end
      end
      resources :ignore_urls, concerns: :deletion
      resource :site_setting
    end

    namespace 'ldap' do
      get '/' => redirect { |p, req| "#{req.path}/setting" }, as: :main
      resource :setting, only: %i[show edit update]
      get "server" => "servers#main", as: "server_main"
      resource :server, only: [:show], path: "server/:dn" do
        get :group
        get :user
      end
      resources :imports, concerns: :deletion, only: [:index, :show, :destroy] do
        get :import_confirmation, on: :collection
        post :import, on: :collection
        get :sync_confirmation, on: :member
        post :sync, on: :member
      end
      resources :result, only: [:index]
    end

    namespace "apis" do
      get "groups" => "groups#index"
      get "nodes" => "nodes#index"
      get "nodes/routes" => "nodes#routes"
      get "pages" => "pages#index"
      get "pages/children" => "pages/children#index"
      get "pages/categorized" => "pages/categorized#index"
      get "pages/routes" => "pages#routes"
      get "categories" => "categories#index"
      get "contents" => "contents#index"
      get "contents/html" => "contents/html#index"
      get "members" => "members#index"
      get "sites" => "sites#index"
      get "layouts" => "layouts#index"
      put "reload_site_usages" => "site_usages#reload"
      get "users" => "users#index"
      get "forms" => "forms#index"
      get "forms/temp_file/:id/select" => "forms#select_temp_file", as: :form_temp_file_select
      get "forms/:id/form" => "forms#form", as: :form
      get "forms/:id/column_names" => "forms#column_names", as: :form_column_names
      get "forms/:id/columns/:column_id/new" => "forms#new_column", as: :form_column_new
      match "forms/:id/html" => "forms#html", as: :form_html, via: %i[post put]
      match "forms/:id/link_check" => "forms#link_check", as: :form_link_check, via: %i[post put]
      post "validation" => "validation#validate"
      post "initialize" => "large_file_upload#init_files"
      post "upload" => "large_file_upload#create"
      put "finalize" => "large_file_upload#finalize"
      post "run" => "large_file_upload#run"
      delete "delete_init_files" => "large_file_upload#delete_init_files"

      resources :files, path: ":cid/files", concerns: [:deletion, :file_api] do
        get :contrast_ratio, on: :collection
      end
      resources :user_files, path: ":cid/user_files", concerns: [:deletion, :file_api] do
        get :contrast_ratio, on: :collection
      end
      resources :temp_files, concerns: [:deletion, :file_api] do
        get :contrast_ratio, on: :collection
      end
      resources :content_files, only: [] do
        get :view, on: :member
        get :contrast_ratio, on: :collection
      end
      resources :replace_files, path: ":owner_item_id/replace_files", only: [:edit, :update] do
        get :confirm, on: :member
        post :confirm, on: :member
        get :histories, on: :member
        get :download, on: :member
        post :restore, on: :member
        post :destroy, on: :member
      end
      scope "node:cid/cms", as: "node", cid: /\w+/ do
        resources :temp_files, controller: 'node/temp_files', concerns: [:deletion, :file_api] do
          get :contrast_ratio, on: :collection
        end
        resources :replace_files, path: ":owner_item_id/replace_files", only: [:edit, :update] do
          get :confirm, on: :member
          post :confirm, on: :member
          get :histories, on: :member
          get :download, on: :member
          post :restore, on: :member
          post :destroy, on: :member
        end
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
          get :new_page, on: :collection
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

      namespace "line" do
        get "deliver_members/:model/:id" => "deliver_members#index",
          model: /message|deliver_condition|line_deliver/, as: :deliver_members
        get "deliver_members/:model/:id/download" => "deliver_members#download",
          model: /message|deliver_condition|line_deliver/
        get "temp_files/:id" => "temp_files#select", as: :select_temp_file
      end

      match "mobile_size_check/check" => "mobile_size_check#check", via: [:post, :options], as: "mobile_size_check"
      post "syntax_check/check" => "syntax_check#check", as: "check_syntax_check"
      post "syntax_check/correct" => "syntax_check#correct", as: "correct_syntax_check"
      post "backlink_check/check" => "backlink_check#check", as: "backlink_check"
    end
  end

  namespace "cms", path: ".cms" do
    match "link_check/check" => "link_check#check", via: [:post, :options], as: "link_check"
  end

  content "cms", name: "node", module: "cms/node" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    get "generate_nodes" => "generate_nodes#index"
    post "generate_nodes" => "generate_nodes#run"
    get "generate_nodes/download_logs" => "generate_nodes#download_logs"
    get "generate_pages" => "generate_pages#index"
    post "generate_pages" => "generate_pages#run"
    get "generate_pages/download_logs" => "generate_pages#download_logs"
    get "import" => "import#import"
    post "import" => "import#import"
    get "import/download_logs" => "import#download_logs"
    get "command" => "command#command"
    post "command" => "command#command"
    get "copy_nodes" => "copy_nodes#index", as: :copy
    post "copy_nodes" => "copy_nodes#run"
    resource :conf, concerns: [:copy, :move, :command] do
      get :delete, on: :member
    end
    resources :max_file_sizes, concerns: :deletion
    resources :image_resizes, concerns: :deletion
    resources :nodes, concerns: [:deletion, :change_state, :import] do  
      match :download, on: :collection, via: %i[get post]
    end
    resources :pages, concerns: [:deletion, :copy, :move, :lock, :command, :contains_urls, :michecker, :change_state] do
      post :resume_new, on: :collection
      post :resume_edit, on: :member
      put :publish_all, on: :collection
      put :close_all, on: :collection
    end
    resources :import_pages, concerns: [:deletion, :convert, :change_state]
    resources :import_nodes, concerns: [:deletion, :change_state]
    get "/group_pages" => redirect { |p, req| "#{req.path.sub(/\/group_pages$/, "")}/nodes" }
    resources :parts, concerns: :deletion
    resources :layouts, concerns: :deletion
    resources :archives, only: [:index]
    resources :photo_albums, only: [:index]
    resources :site_searches, only: [:index]
    resources :form_searches, only: [:index]
    get "search_contents/:id" => "page_search_contents#show", as: "page_search_contents"
    get "search_contents/:id/download" => "page_search_contents#download", as: "download_page_search_contents"
    delete "search_contents/:id" => "page_search_contents#destroy_all"
    resources :line_hubs, only: [:index]
  end

  node "cms" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
    get "page/rss-recent.xml" => "public#rss_recent", cell: "nodes/page", format: "xml"
    get "group_page/(index.:format)" => "public#index", cell: "nodes/group_page"
    get "group_page/rss.xml" => "public#rss", cell: "nodes/group_page", format: "xml"
    get "group_page/rss-recent.xml" => "public#rss_recent", cell: "nodes/group_page", format: "xml"
    get "import_node/(index.:format)" => "public#index", cell: "nodes/import_node"
    get "archive/:ymd/(index.:format)" => "public#index", cell: "nodes/archive", ymd: /\d+/
    get "archive" => "public#redirect_to_archive_index", cell: "nodes/archive"
    get "photo_album" => "public#index", cell: "nodes/photo_album"
    get "site_search/(index.:format)" => "public#index", cell: "nodes/site_search"
    get "site_search/categories(.:format)" => "public#categories", cell: "nodes/site_search"
    get "form_search/(index.:format)" => "public#index", cell: "nodes/form_search"
    get "line_hub/(index.:format)" => "public#index", cell: "nodes/line_hub"
    get "line_hub/line" => "public#line", cell: "nodes/line_hub"
    post "line_hub/line" => "public#line", cell: "nodes/line_hub"
    get "line_hub/image-map/:id/:size" => "public#image_map", cell: "nodes/line_hub"
    get "line_hub/mail/:filename" => "public#mail", cell: "nodes/line_hub"
    post "line_hub/mail/:filename" => "public#mail", cell: "nodes/line_hub"
    get "line_hub/dump_garbage/:id/:size" => "public#dump_garbage", cell: "nodes/line_hub"
  end

  part "cms" do
    get "free" => "public#index", cell: "parts/free"
    get "node" => "public#index", cell: "parts/node"
    get "node2" => "public#index", cell: "parts/node2"
    get "page" => "public#index", cell: "parts/page"
    get "tabs" => "public#index", cell: "parts/tabs"
    get "crumb" => "public#index", cell: "parts/crumb"
    get "sns_share" => "public#index", cell: "parts/sns_share"
    get "calendar_nav" => "public#index", cell: "parts/calendar_nav"
    get "monthly_nav" => "public#index", cell: "parts/monthly_nav"
    get "site_search_history" => "public#index", cell: "parts/site_search_history"
    get "history_list" => "public#index", cell: "parts/history_list"
    get "site_search_keyword" => "public#index", cell: "parts/site_search_keyword"
    get "print" => "public#index", cell: "parts/print"
    get "clipboard_copy" => "public#index", cell: "parts/clipboard_copy"
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

  match "*public_path" => "cms/public#index", public_path: /[^.].*/,
    via: [:get, :post, :put, :patch, :delete], format: true
  match "*public_path" => "cms/public#index", public_path: /[^.].*/,
    via: [:get, :post, :put, :patch, :delete], format: false

  root "cms/public#index", defaults: { format: :html }
end
