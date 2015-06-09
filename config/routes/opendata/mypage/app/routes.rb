SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    resources :my_apps, concerns: :deletion, module: "mypage/app"
  end

  node "opendata" do
    resources :apps, path: "my_app", controller: "public", cell: "nodes/mypage/app/my_app", concerns: :deletion do
      resources :appfiles, controller: "public", cell: "nodes/mypage/app/my_app/appfiles", concerns: :deletion do
        get "file" => "public#download"
      end
    end
  end
end
