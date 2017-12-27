SS::Application.routes.draw do
  Gws::Monitor::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :state_change do
    post :public, on: :member
    post :preparation, on: :member
    post :question_not_applicable, on: :member
    post :public_all, on: :collection
    post :preparation_all, on: :collection
    post :question_not_applicable_all, on: :collection
  end

  concern :topic_comment do
    namespace :parent, path: ":parent_id", parent_id: /\d+/ do
      resources :comments, controller: '/gws/monitor/comments', concerns: [:deletion]
    end
    # get :categories, on: :collection
  end

  gws 'monitor' do
    get '/' => redirect { |p, req| "#{req.path}/-/topics" }, as: :main

    scope(path: ":category") do
      resources :topics, concerns: [:state_change, :topic_comment], except: [:new, :create, :edit, :update, :destroy] do
        get :forward, on: :member
      end
      resources :answers, concerns: [:state_change, :topic_comment], except: [:new, :create, :edit, :update, :destroy] do
        get :forward, on: :member
      end

      resources :admins, concerns: [:state_change, :topic_comment], except: [:destroy] do
        match :publish, on: :member, via: %i[get post]
        match :disable, on: :member, via: %i[get post]
        post :disable_all, on: :collection
        post :close, on: :member
        post :open, on: :member
        get :download, on: :member
        get :file_download, on: :member
      end
      resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
        match :active, on: :member, via: %i[get post]
        post :active_all, on: :collection
      end

      namespace "management" do
        get '/' => redirect { |p, req| "#{req.path}/topics" }, as: :main

        resources :topics, concerns: [:state_change, :topic_comment], except: [:new, :create, :destroy] do
          match :disable, on: :member, via: %i[get post]
          post :disable_all, on: :collection
          get :download, on: :member
          post :close, on: :member
          post :open, on: :member
          get :file_download, on: :member
        end
        resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
          match :active, on: :member, via: %i[get post]
          post :active_all, on: :collection
        end
      end
    end

    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
    end
  end
end

