Rails.application.routes.draw do
  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  gws "search_form" do
    resources :targets, concerns: [:deletion]
  end
end
