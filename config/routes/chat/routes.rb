SS::Application.routes.draw do

  Chat::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  namespace "chat", path: ".s:site/chat" do
    namespace 'apis' do
      get 'categories' => 'categories#index'
    end
  end

  content "chat" do
    get "/" => redirect { |p, req| "#{req.path}/intents" }, as: :main
    get "/bots" => redirect { |p, req| "#{req.path}/../intents" }
    resources :intents, concerns: :deletion
    resources :categories, concerns: :deletion
  end

  node "chat" do
    get "bot/(index.:format)" => "public#index", cell: "nodes/bot"
  end

  part "chat" do
    get "bot/(index.:format)" => "public#index", cell: "parts/bot"
  end
end
