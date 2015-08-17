class ActionDispatch::Routing::Mapper
  def sys(ns, opts = {}, &block)
    name = opts[:name] || ns.gsub("/", "_")
    mod  = opts[:module] || ns
    namespace(name, as: "#{name}_sys", path: ".sys/#{ns}", module: "#{mod}/sys") { yield }
  end

  def cms(ns, opts = {}, &block)
    name = opts[:name] || ns.gsub("/", "_")
    mod  = opts[:module] || ns
    namespace(name, as: "#{name}_cms", path: ".s:site/#{ns}", module: "#{mod}/cms") { yield }
  end

  def content(ns, opts = {}, &block)
    name = opts[:name] || ns.gsub("/", "_")
    mod  = opts[:module] || ns
    namespace(name, path: ".s:site/#{ns}:cid", module: mod, cid: /\w+/) { yield }
  end

  def node(ns, &block)
    name = ns.gsub("/", "_")
    path = ".s:site/nodes/#{ns}"
    namespace(name, as: "#{name}_node", path: path, module: "cms") { yield }
  end

  def page(ns, &block)
    name = ns.gsub("/", "_")
    path = ".s:site/pages/#{ns}"
    namespace(name, as: "#{name}_page", path: path, module: "cms") { yield }
  end

  def part(ns, &block)
    name = ns.gsub("/", "_")
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
    get   "auth_token" => "auth_token#index", as: :auth_token
  end

end
