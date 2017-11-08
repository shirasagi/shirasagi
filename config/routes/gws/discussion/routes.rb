SS::Application.routes.draw do
  Gws::Discussion::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :plans do
    get :events, on: :collection
    get :print, on: :collection
    get :popup, on: :member
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :todos do
    get :finish, on: :member
    get :revert, on: :member
    get :disable, on: :member
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  gws 'discussion' do
    get '/' => redirect { |p, req| "#{req.path}/topics" }, as: :main

    resources :forums, concerns: [:deletion, :copy] do
      resources :topics, concerns: [:deletion, :copy] do
        get :all, on: :collection
        put :reply, on: :member
        resources :comments, controller: '/gws/discussion/comments', concerns: [:deletion] do
          put :reply, on: :collection
        end
      end
      resources :todos, concerns: [:plans, :todos, :copy]
    end
  end
end
