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
    get "apps_approve" => "app/apps#index_approve"
    get "apps_request" => "app/apps#index_request"
    get "apps_closed" => "app/apps#index_closed"
    resources :my_apps, concerns: :deletion_all, module: "mypage/app"
  end

  node "opendata" do
    resources :apps, path: "my_app", controller: "public", cell: "nodes/mypage/app/my_app", concerns: :deletion do
      resources :appfiles, controller: "public", cell: "nodes/mypage/app/my_app/appfiles", concerns: :deletion do
        get "file" => "public#download"
      end
    end
  end
end
