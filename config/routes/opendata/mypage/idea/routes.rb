SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    resources :my_ideas, concerns: :deletion
  end

  node "opendata" do
    resources :ideas, path: "my_idea", controller: "public", cell: "nodes/my_idea", concerns: :deletion
  end
end
