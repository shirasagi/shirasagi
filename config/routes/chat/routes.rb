SS::Application.routes.draw do

  Chat::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
    get :download_record_phrases, on: :collection
    get :download_exists_phrases, on: :collection
    get :download_sessions, on: :collection
    get :download_used_times, on: :collection
  end

  concern :import do
    match :import, on: :collection, via: %i[get post]
  end

  namespace "chat", path: ".s:site/chat" do
    namespace 'apis' do
      get 'categories' => 'categories#index'
    end
  end

  content "chat" do
    get "/" => redirect { |p, req| "#{req.path}/intents" }, as: :main
    get "/bots" => redirect { |p, req| "#{req.path}/../intents" }
    resources :intents, concerns: [:deletion, :download, :import]
    resources :categories, concerns: :deletion
    resources :histories, concerns: [:deletion, :download], only: [:index, :show, :destroy]
    resources :line_reports, concerns: [:download], only: [:index]
    get 'report' => 'report#index'
  end

  node "chat" do
    get "bot/(index.:format)" => "public#index", cell: "nodes/bot"
    post "bot/line" => "public#line", cell: "nodes/bot"
  end

  part "chat" do
    get "bot/(index.:format)" => "public#index", cell: "parts/bot"
  end
end
