SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :deletion_all do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  content "opendata" do
    resources :mypages, concerns: :deletion_all, module: "mypage"
  end

  node "opendata" do
    get "mypage/(index.html)" => "public#index", cell: "nodes/mypage/mypage"
    get "mypage/notice/show.:format" => "public#show_notice", cell: "nodes/mypage/mypage", format: false
    get "mypage/notice/confirm.:format" => "public#confirm_notice", cell: "nodes/mypage/mypage", format: false

    resource :profile, path: "my_profile", controller: "public", cell: "nodes/mypage/my_profile", concerns: :deletion
  end

  part "opendata" do
    get "mypage_login" => "public#index", cell: "parts/mypage/mypage_login"
  end
end
