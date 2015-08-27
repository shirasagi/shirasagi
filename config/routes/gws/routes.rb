SS::Application.routes.draw do
  Gws::Initializer

  get '.g:group/', to: 'gws/portal#index', as: :gws_portal

  namespace "gws", path: ".g:group/gws" do
  #gws "gws" do
    resources :users#, only: [:index, :show, :edit, :update]
    resources :roles do
      get :delete, on: :member
    end
  end
  # TODO integrate / (as portal) and gws/roles

  # WIP
  #gws "reservation" do
  #  resources :plans
  #end
end
