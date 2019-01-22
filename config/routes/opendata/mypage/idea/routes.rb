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
    match "ideas_approve" => "idea/ideas#index_approve", via: [:get, :delete]
    match "ideas_request" => "idea/ideas#index_request", via: [:get, :delete]
    match "ideas_closed" => "idea/ideas#index_closed", via: [:get, :delete]
    resources :my_ideas, concerns: :deletion_all, module: "mypage/idea"
  end

  node "opendata" do
    resources :ideas, path: "my_idea", controller: "public", cell: "nodes/mypage/idea/my_idea", concerns: :deletion
  end
end
