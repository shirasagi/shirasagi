SS::Application.routes.draw do

  Chat::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  namespace "chat", path: ".s:site/chat" do
    get "/" => "main#index"
    resources :intents, concerns: [:deletion]
    resources :categories, concerns: [:deletion]
    namespace 'apis' do
      get 'categories' => 'categories#index'
    end
  end

  part "chat" do
    get "bot" => "public#index", cell: "parts/bot"
  end
end
