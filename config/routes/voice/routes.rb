SS::Application.routes.draw do

  Voice::Initializer

  concern :deletion_and_source do
    get :delete, on: :member
    get :file, on: :member
  end

  namespace "voice", path: ".voice" do
    get "/*path" => "main#index", format: false
    get "/" => "main#index", format: false
  end

  namespace("voice", as: "voice", path: ".:site/voice", module: "voice") do
    get "voice_files/download" => "voice_files#download"
    resources :voice_files, concerns: :deletion_and_source, except: [:create, :edit, :new, :update]
    get "error_files/download" => "error_files#download"
    resources :error_files, concerns: :deletion_and_source, except: [:create, :edit, :new, :update]
  end

end
