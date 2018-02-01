SS::Application.routes.draw do

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, on: :collection
  end

  namespace "sns", path: ".u" do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }, as: :cur_user
    get "connection" => "connection#index", as: :connection

    resource :user_profile, as: :cur_user_profile, only: [:show]
    resource :user_account, as: :cur_user_account

    resources :user_files, concerns: :deletion, as: :cur_user_files do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
      get :resize, on: :member
      post :resize, on: :member
    end
    get "download_job_files/:filename" => "download_job_files#index",
      filename: %r{[^\/]+}, format: false

    namespace "addons", module: "agents/addons" do
      post "markdown" => "markdown#preview"
    end
  end

  namespace "sns", path: ".u:user", user: /\d+/ do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }

    resource :user_profile, only: [:show]
    resource :user_account

    resources :user_files, concerns: :deletion do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
    end
    get "download_job_files/:filename(/:name)" => "download_job_files#index",
      filename: %r{[^\/]+}, name: %r{[^\/]+}, format: false, as: :download_job_files

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
