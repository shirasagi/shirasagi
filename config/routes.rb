class ActionDispatch::Routing::Mapper
  def sys(ns, opts = {}, &block)
    name = opts[:name] || ns.tr("/", "_")
    mod  = opts[:module] || ns
    namespace(name, as: "#{name}_sys", path: ".sys/#{ns}", module: "#{mod}/sys") { yield }
  end

  def gws(ns, &block)
    namespace(ns, as: "gws_#{ns}", path: ".g:site/#{ns}", module: "gws/#{ns}", site: /\d+/) { yield }
  end

  def cms(ns, opts = {}, &block)
    name = opts[:name] || ns.tr("/", "_")
    mod  = opts[:module] || ns
    namespace(name, as: "#{name}_cms", path: ".s:site/#{ns}", module: "#{mod}/cms") { yield }
  end

  def content(ns, opts = {}, &block)
    name = opts[:name] || ns.tr("/", "_")
    mod  = opts[:module] || ns
    namespace(name, path: ".s:site/#{ns}:cid", module: mod, cid: /\w+/) { yield }
  end

  def node(ns, &block)
    name = ns.tr("/", "_")
    path = ".s:site/nodes/#{ns}"
    namespace(name, as: "#{name}_node", path: path, module: "cms") { yield }
  end

  def page(ns, &block)
    name = ns.tr("/", "_")
    path = ".s:site/pages/#{ns}"
    namespace(name, as: "#{name}_page", path: path, module: "cms") { yield }
  end

  def part(ns, &block)
    name = ns.tr("/", "_")
    path = ".s:site/parts/#{ns}"
    namespace(name, as: "#{name}_part", path: path, module: "cms") { yield }
  end
end

SS::Application.routes.draw do
  SS::Initializer

  namespace "sns", path: ".mypage" do
    get   "/"      => "mypage#index", as: :mypage
    get   "logout" => "login#logout", as: :logout
    match "login"  => "login#login", as: :login, via: [:get, :post]
    match "remote_login" => "login#remote_login", as: :remote_login, via: [:get, :post]
    resources :public_notices, only: [:index, :show]
    resources :sys_notices, only: [:index, :show]
    get   "status" => "login#status", as: :login_status
    get   "auth_token" => "auth_token#index", as: :auth_token
    get   "cms" => "mypage#cms"
    get   "gws" => "mypage#gws"

    namespace "login" do
      # SAML SSO
      get  "saml/:id/init" => "saml#init", as: :saml
      post "saml/:id/consume" => "saml#consume"
      get  "saml/:id/metadata" => "saml#metadata", as: :saml_metadata

      # OpenID Connect SSO
      get  "oid/:id/init" => "open_id_connect#init", as: :open_id_connect
      match "oid/:id/callback" => "open_id_connect#callback", as: :open_id_connect_callback, via: [:get, :post]

      # Environment
      get "env/:id/login" => "environment#login", as: :env
    end
  end
end
