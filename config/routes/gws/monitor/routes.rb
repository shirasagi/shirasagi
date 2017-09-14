SS::Application.routes.draw do
  Gws::Monitor::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'monitor' do
    resources :topics, concerns: [:deletion] do
      post :public_all, on: :collection
      post :preparation_all, on: :collection
      post :qNA_all, on: :collection
    end
  end
end