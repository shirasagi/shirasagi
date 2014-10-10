SS::Application.routes.draw do

  Event::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "event" do
    get "/" => "main#index", as: :main
    resources :pages, concerns: :deletion
  end

  node "event" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/:year:month.:format" => "public#index", cell: "nodes/page",
      year: /\d{4}/, month: /\d{2}/
  end

  page "event" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
