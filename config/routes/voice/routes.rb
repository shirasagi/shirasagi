SS::Application.routes.draw do

  Voice::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  concern :file do
    get :file, on: :member
  end

  concern :download do
    get :download, on: :collection
  end

  namespace "voice", path: ".voice" do
    get "/*path" => "main#index", format: false
    get "/" => "main#index", format: false
  end

  namespace("voice", as: "voice", path: ".s:site/voice", module: "voice") do
    resources :files, concerns: [:download, :deletion, :file], except: [:create, :edit, :new, :update]
    resources :error_files, concerns: [:download, :deletion, :file], except: [:create, :edit, :new, :update]
  end

end
