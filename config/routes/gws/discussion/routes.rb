Rails.application.routes.draw do
  Gws::Discussion::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :plans do
    get :events, on: :collection
    get :print, on: :collection
    get :popup, on: :member
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :todos do
    match :finish, on: :member, via: %i[get post]
    match :revert, on: :member, via: %i[get post]
    match :soft_delete, on: :member, via: [:get, :post]
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  gws 'discussion' do
    get '/' => redirect { |p, req| "#{req.path}/-/forums" }, as: :main

    scope path: ':mode' do
      resources :forums, concerns: [:soft_deletion, :copy], except: [:destroy] do
        get 'portal' => "portal#index"
        get 'portal/search' => "portal#search"
        put 'portal/reply/:id' => "portal#reply"
        namespace "portal" do
          resources :topics, only: [:new, :create]
          scope path: "topic:topic_id" do
            resources :comments, only: [:edit, :update, :destroy], concerns: [:deletion]
          end
        end
        namespace "thread" do
          resources :topics, only: [:edit, :update, :destroy], concerns: [:deletion, :copy]
          scope path: "topic:topic_id" do
            resources :comments, concerns: [:deletion] do
              put :reply, on: :collection
            end
          end
        end
        resources :todos, concerns: [:plans, :todos, :copy]
        resources :bookmarks, only: [:index, :destroy], concerns: [:deletion]
        resources :topics, concerns: [:deletion, :copy]
      end
    end

    resources :trashes, concerns: [:deletion, :copy], except: [:new, :create, :edit, :update] do
      match :undo_delete, on: :member, via: [:get, :post]
    end

    namespace "apis" do
      get 'unseen/:id' => "unseen#index", id: /\d+/, as: :unseen
      scope path: 'forums/:forum_id/todos/:todo_id', as: :forum_todo do
        resources :comments, controller: "/gws/schedule/todo/apis/comments",
                  concerns: [:deletion], except: [:index, :new, :show, :destroy_all]
      end
      post "bookmark/:forum_id/:id" => "bookmark#index", id: /\d+/, as: :bookmark
    end
  end
end
