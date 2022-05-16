Rails.application.routes.draw do

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :file_api do
    get :select, on: :member
    get :selected_files, on: :collection
    get :view, on: :member
    get :thumb, on: :member
    get :download, on: :member
  end

  namespace "sns", path: ".u" do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }, as: :cur_user
    get "connection" => "connection#index", as: :connection

    resource :user_profile, as: :cur_user_profile, only: [:show]
    resource :user_account, as: :cur_user_account do
      get :edit_password, on: :member
      post :update_password, on: :member
    end

    resources :user_files, concerns: [:deletion, :file_api], as: :cur_user_files do
      get :resize, on: :member
      post :resize, on: :member
      get :contrast_ratio, on: :collection
    end
    get "download_job_files/:filename" => "download_job_files#index",
      filename: %r{[^/]+}, format: false

    namespace "addons", module: "agents/addons" do
      post "markdown" => "markdown#preview"
    end

    resources :notifications, concerns: :deletion, only: [:index, :show, :destroy] do
      get :recent, on: :collection
      get :latest, on: :collection
    end
  end

  namespace "sns", path: ".u:user", user: /\d+/ do
    #
    # 注意: 本ブロックにルーティンを追加される方へ。
    #
    # 本当にこのブロックへルーティングを追加する必要がありますか？
    # 追加しようとしているルーティングは、他人のものを操作する必要があるのでしょうか？
    #
    # 本来は不要なルーティングが歴史的な理由により残っていますが、
    # ここのブロックには「他人のプロフィールを閲覧する」や「他人のアカウト情報を閲覧する」など、
    # 他人のものを操作する必要がある場合だけに限るべきです。
    #
    # 自分のものだけを操作できれば十分（通常はこれで十分）な場合は、上のブロックにルーティングを追加してください。
    #
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }

    resource :user_profile, only: [:show]
    resource :user_account

    resources :user_files, concerns: [:deletion, :file_api]
    get "download_job_files/:filename(/:name)" => "download_job_files#index",
      filename: %r{[^/]+}, name: %r{[^/]+}, format: false, as: :download_job_files

    namespace "apis" do
      resources :temp_files, concerns: [:deletion, :file_api] do
        get :contrast_ratio, on: :collection
      end
      resources :user_files, concerns: [:deletion, :file_api] do
        get :contrast_ratio, on: :collection
      end
    end
  end
end
