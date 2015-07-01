SS::Application.routes.draw do

  concern :deletion do
    get :delete, :on => :member
  end

  namespace "sns", path: ".u:user", user: /\d+/ do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }

    resource :user_profile
    resource :user_account

    resources :user_files, concerns: :deletion do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
    end

    namespace "apis" do
      resources :temp_files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end

      resources :user_files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end
    end
  end
end
