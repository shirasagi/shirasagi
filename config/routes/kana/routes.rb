SS::Application.routes.draw do

  Kana::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  namespace("kana", as: "kana", path: ".s:site/kana", module: "kana") do
    get "dictionaries/build_confirmation" => "dictionaries#build_confirmation"
    post "dictionaries/build" => "dictionaries#build"
    resources :dictionaries, concerns: :deletion
  end
end
