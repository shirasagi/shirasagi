SS::Application.routes.draw do
  Gws::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  namespace "gws", path: ".g:site/gws" do
    resources :bookmarks, concerns: [:deletion]
    namespace "apis" do
      post "bookmarks" => "bookmarks#index"
    end
  end
end
