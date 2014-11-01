SS::Application.routes.draw do

  Event::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "event" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: :deletion
  end

  node "event" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/:year:month.:format" => "public#monthly", cell: "nodes/page",
      year: /\d{4}/, month: /\d{2}/
    get "page/:year:month:day.:format" => "public#daily", cell: "nodes/page",
      year: /\d{4}/, month: /\d{2}/, day: /\d{2}/
  end

  part "event" do
    get "calendar" => "public#index", cell: "parts/calendar"
  end

  page "event" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

  namespace "event", path: ".:site/event" do
    get "/search_categories" => "search_categories#index"
  end

end
