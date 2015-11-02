SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    get "ideas_approve" => "idea/ideas#index_approve"
    get "ideas_request" => "idea/ideas#index_request"
    get "ideas_closed" => "idea/ideas#index_closed"
    resources :my_ideas, concerns: :deletion, module: "mypage/idea"
  end

  node "opendata" do
    resources :ideas, path: "my_idea", controller: "public", cell: "nodes/mypage/idea/my_idea", concerns: :deletion
  end
end
