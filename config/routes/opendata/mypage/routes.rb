SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    resources :mypages, concerns: :deletion
    resources :members, only: [:index]
  end

  node "opendata" do
    get "member/" => "public#index", cell: "nodes/member"
    get "member/:member" => "public#show", cell: "nodes/member"
    get "member/:member/datasets/(:filename.:format)" => "public#datasets", cell: "nodes/member"
    get "member/:member/apps/(:filename.:format)" => "public#apps", cell: "nodes/member"
    get "member/:member/ideas/(:filename.:format)" => "public#ideas", cell: "nodes/member"

    get "mypage/(index.html)" => "public#index", cell: "nodes/mypage"
    get "mypage/login"  => "public#login", cell: "nodes/mypage"
    post "mypage/login" => "public#login", cell: "nodes/mypage"
    get "mypage/logout" => "public#logout", cell: "nodes/mypage"
    get "mypage/notice/show.:format" => "public#show_notice", cell: "nodes/mypage", format: false
    get "mypage/notice/confirm.:format" => "public#confirm_notice", cell: "nodes/mypage", format: false
    get "mypage/:provider" => "public#provide", cell: "nodes/mypage"

    resource :profile, path: "my_profile", controller: "public", cell: "nodes/my_profile", concerns: :deletion
  end

  part "opendata" do
    get "mypage_login" => "public#index", cell: "parts/mypage_login"
  end

end
