class ActionDispatch::Routing::Mapper
  def sys(ns, **opts, &block)
    name = opts[:name] || ns.tr("/", "_")
    mod  = opts[:module] || ns
    namespace(name, as: "#{name}_sys", path: ".sys/#{ns}", module: "#{mod}/sys", &block)
  end

  def gws(ns, &block)
    namespace(ns, as: "gws_#{ns}", path: ".g:site/#{ns}", module: "gws/#{ns}", site: /\d+/, &block)
  end

  def cms(ns, **opts, &block)
    name = opts[:name] || ns.tr("/", "_")
    mod  = opts[:module] || ns
    namespace(name, as: "#{name}_cms", path: ".s:site/#{ns}", module: "#{mod}/cms", &block)
  end

  def sns(ns, **opts, &block)
    name = opts[:name] || ns.tr("/", "_")
    mod  = opts[:module] || ns
    namespace(name, as: "#{name}_sns", path: ".u/#{ns}", module: "#{mod}/sns", &block)
  end

  def content(ns, **opts, &block)
    name = opts[:name] || ns.tr("/", "_")
    mod  = opts[:module] || ns
    namespace(name, path: ".s:site/#{ns}-:cid", module: mod, cid: /\d+/, &block)
  end

  def node(ns, &block)
    name = ns.tr("/", "_")
    path = ".s:site/nodes/#{ns}"
    namespace(name, as: "#{name}_node", path: path, module: "cms", &block)
  end

  def page(ns, &block)
    name = ns.tr("/", "_")
    path = ".s:site/pages/#{ns}"
    namespace(name, as: "#{name}_page", path: path, module: "cms", &block)
  end

  def part(ns, &block)
    name = ns.tr("/", "_")
    path = ".s:site/parts/#{ns}"
    namespace(name, as: "#{name}_part", path: path, module: "cms", &block)
  end
end

Rails.application.routes.draw do
  SS::Initializer

  namespace "sns", path: ".mypage" do
    get   "/"      => "mypage#index", as: :mypage
    get   "logout" => "login#logout", as: :logout
    match "login"  => "login#login", as: :login, via: [:get, :post]
    match "remote_login" => "login#remote_login", as: :remote_login, via: [:get, :post]
    get   "mfa_login" => "mfa_login#login", as: :mfa_login
    post  "otp_login" => "mfa_login#otp_login"
    post  "otp_setup" => "mfa_login#otp_setup"
    get   "redirect" => "login#redirect", as: :redirect
    get   "login_image" => "login_image#index", as: :login_image
    resources :public_notices, only: [:index, :show] do
      get :frame_content, on: :member
    end
    resources :sys_notices, only: [:index, :show] do
      get :frame_content, on: :member
    end
    get   "status" => "login#status", as: :login_status
    get   "auth_token" => "auth_token#index", as: :auth_token
    get   "cms" => "mypage#cms"
    get   "gws" => "mypage#gws"
    get   "locales/default/:languages/:namespace" => "locales#default", as: :locale_default
    post  "locales/fallback/:languages/:namespace" => "locales#fallback", as: :locale_fallback

    namespace "login" do
      # SAML SSO
      get  "saml/:id/init" => "saml#init", as: :saml
      post "saml/:id/consume" => "saml#consume"
      get  "saml/:id/metadata" => "saml#metadata", as: :saml_metadata

      # OpenID Connect SSO
      get  "oid/:id/init" => "open_id_connect#init", as: :open_id_connect
      match "oid/:id/callback" => "open_id_connect#callback", as: :open_id_connect_callback, via: [:get, :post]
      if Rails.env.test?
        get "oid/:id/implicit" => "open_id_connect#implicit", as: :open_id_connect_implicit
        get "oid/:id/authorization_code" => "open_id_connect#authorization_code", as: :open_id_connect_authorization_code
        post "oid/:id/authorization_token" => "open_id_connect#authorization_token", as: :open_id_connect_authorization_token
      end

      # Environment
      get "env/:id/login" => "environment#login", as: :env

      # OAuth2
      get "oauth2/authorize" => "oauth2#authorize"
      post "oauth2/token" => "oauth2#token"
    end
  end

  namespace :cms do
    namespace :apis do
      get 'youtube_title', to: 'youtube#fetch_title'
    end
  end
end
