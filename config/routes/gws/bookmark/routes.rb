SS::Application.routes.draw do
  Gws::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  namespace "gws", path: ".g:site/gws" do
    resources :bookmarks, concerns: [:deletion]
    namespace "apis" do
      resources :bookmarks, only: [:create, :update, :destroy]
    end
  end
end
