Rails.application.routes.draw do

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end
end
