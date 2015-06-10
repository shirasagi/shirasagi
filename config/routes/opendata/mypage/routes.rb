SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    resources :mypages, concerns: :deletion, module: "mypage"
  end

  node "opendata" do
    get "mypage/(index.html)" => "public#index", cell: "nodes/mypage/mypage"
    get "mypage/login"  => "public#login", cell: "nodes/mypage/mypage"
    post "mypage/login" => "public#login", cell: "nodes/mypage/mypage"
    get "mypage/logout" => "public#logout", cell: "nodes/mypage/mypage"
    get "mypage/notice/show.:format" => "public#show_notice", cell: "nodes/mypage/mypage", format: false
    get "mypage/notice/confirm.:format" => "public#confirm_notice", cell: "nodes/mypage/mypage", format: false
    get "mypage/:provider" => "public#provide", cell: "nodes/mypage/mypage"

    resource :profile, path: "my_profile", controller: "public", cell: "nodes/mypage/my_profile", concerns: :deletion
  end

  part "opendata" do
    get "mypage_login" => "public#index", cell: "parts/mypage/mypage_login"
  end
end
