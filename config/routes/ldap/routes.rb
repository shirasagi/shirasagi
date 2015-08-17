SS::Application.routes.draw do

  Ldap::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  namespace("ldap", as: "ldap", path: ".s:site/ldap", module: "ldap") do
    get "server/:dn/group" => "server#group"
    get "server/:dn/user" => "server#user"
    get "server/:dn" => "server#index"
    get "server" => "server#index"
    get "import/import_confirmation" => "import#import_confirmation"
    post "import/import" => "import#import"
    get "import/sync_confirmation/:id" => "import#sync_confirmation"
    post "import/sync/:id" => "import#sync"
    get "import/results/:id" => "import#results"
    resources :import, concerns: :deletion, except: [:new, :create, :edit, :update]
  end
end
