SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :deletion_all do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  content "opendata" do
    match "apps_approve" => "app/apps#index_approve", via: [:get, :delete]
    match "apps_request" => "app/apps#index_request", via: [:get, :delete]
    match "apps_closed" => "app/apps#index_closed", via: [:get, :delete]
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
