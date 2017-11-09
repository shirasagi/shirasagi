SS::Application.routes.draw do
  Gws::Chorg::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'chorg' do
    resources :revisions, concerns: [:deletion]
  end
end
