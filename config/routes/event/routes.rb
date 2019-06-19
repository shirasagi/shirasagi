SS::Application.routes.draw do

  Event::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :crud do
    get :move, on: :member
    put :move, on: :member
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :ical_refresh do
    get :ical_refresh, on: :collection
    post :ical_refresh, on: :collection
  end

  concern :command do
    get :command, on: :member
    post :command, on: :member
  end

  concern :contains_urls do
    get :contains_urls, on: :member
  end

  concern :tag do
    post :tag, action: :set_tag_all, on: :collection
    delete :tag, action: :reset_tag_all, on: :collection
  end

  content "event" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :crud, :download, :import, :ical_refresh, :command, :contains_urls, :tag]
    resources :searches, only: [:index]
  end

  node "event" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/(:display.:format)" => "public#index", cell: "nodes/page", display: /[a-z]*/
    get "page/:year:month/(:display.:format)" => "public#index", cell: "nodes/page",
      year: /\d{4}/, month: /\d{2}/, display: /[a-z]*/
    get "page/:year:month:day/(index.:format)" => "public#daily", cell: "nodes/page",
      year: /\d{4}/, month: /\d{2}/, day: /\d{2}/
    get "search/(index.:format)" => "public#index", cell: "nodes/search"
  end

  part "event" do
    get "calendar" => "public#index", cell: "parts/calendar"
    get "search" => "public#index", cell: "parts/search"
  end

  page "event" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
    get "search/(index.:format)" => "public#index", cell: "node/search"
  end

  namespace "event", path: ".s:site/event" do
    namespace "apis" do
      get "repeat_dates" => "repeat_dates#index"
      put "repeat_dates" => "repeat_dates#create"
    end
  end
end
