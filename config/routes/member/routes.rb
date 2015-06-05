SS::Application.routes.draw do

  Member::Initializer

  content "member" do
    get "/" => redirect { |p, req| "#{req.path}/logins" }, as: :main
    resources :logins, only: [:index]
  end

  node "member" do
    get "login/(index.:format)" => "public#login", cell: "nodes/login"
    match "login/login.html" => "public#login", via: [:get, :post], cell: "nodes/login"
    get "login/logout.html" => "public#logout", cell: "nodes/login"
    get "login/:provider/callback" => "public#callback", cell: "nodes/login"
    get "login/failure" => "public#failure", cell: "nodes/login"
  end

end
