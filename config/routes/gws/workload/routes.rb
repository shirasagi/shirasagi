Rails.application.routes.draw do
  Gws::Workload::Initializer

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    get :download_all, on: :collection
    post :download_all, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :plans do
    get :popup, on: :member
  end

  concern :finish do
    match :finish, on: :member, via: %i[get post]
    match :revert, on: :member, via: %i[get post]
  end

  gws 'workload' do
    get '/' => redirect { |p, req| "#{req.path}/-/-/-/-/-/works" }, as: :main

    scope(path: ':year/:category/:group', defaults: { year: '-', category: '-', group: '-' }) do
      scope(path: ':client/:user', defaults: { client: '-', user: '-' }) do
        resources :works, concerns: [:soft_deletion, :finish, :plans], except: [:destroy]
        resources :admins, concerns: [:soft_deletion, :finish], except: [:destroy]
        resources :trashes, except: [:new, :create, :edit, :update] do
          get :delete, on: :member
          delete :destroy_all, on: :collection, path: ''
          get :recover, on: :member
          match :undo_delete, on: :member, via: [:get, :post]
        end
        resources :overtimes, except: [:new, :create, :destroy]
      end
      scope(path: ':user', defaults: { user: '-' }) do
        resources :graphs, only: [:index] do
          get :download_works, on: :collection
          get :download_work_comments, on: :collection
        end
      end

      resources :categories, concerns: [:deletion, :export]
      resources :clients, concerns: [:deletion, :export]
      resources :cycles, concerns: [:deletion, :export]
      resources :loads, concerns: [:deletion, :export]
      namespace "graph" do
        resources :user_settings, except: [:new, :create, :destroy]
      end
    end

    namespace "apis" do
      scope path: ':work_id' do
        resources :comments, concerns: [:deletion], except: [:index, :new, :show, :destroy_all]
      end
      scope path: ':year/:group' do
        get 'work/:id' => "works#form_options", as: :work_form_options
      end
    end
  end
end
