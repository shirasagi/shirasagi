Rails.application.routes.draw do
  Gws::Workflow2::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :workflow do
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
    post :pull_up_update, on: :member
    post :restart_update, on: :member
    post :seen_update, on: :member
    match :request_cancel, on: :member, via: [:get, :post]
  end

  gws "workflow2" do
    get '/' => redirect { |p, req| "#{req.path}/routes" }, as: :setting
    resources :routes, concerns: :deletion do
      get :template, on: :collection
    end
    scope :files do
      get '/' => redirect { |p, req| "#{req.path}/all" }, as: :files_main
      resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
        match :undo_delete, on: :member, via: [:get, :post]
      end
      resources :select_forms, path: ':state/:mode/forms', only: %i[index]
      resources :files, path: ':state', concerns: [:soft_deletion, :workflow], except: [:destroy] do
        get :comment, on: :member
        get :print, on: :member
        match :copy, on: :member, via: %i[get post]
        post :download_comment, on: :member
        post :download_attachment, on: :member
        post :download_all_comments, on: :collection
        post :download_all_attachments, on: :collection
        post :approve_all, on: :collection
        post :remand_all, on: :collection
      end
      resources :files, path: ':state/:form_id', only: [:new, :create], as: 'form_files'
    end
    namespace "form" do
      resources :applications, concerns: :deletion, as: :forms do
        match :publish, on: :member, via: [:get, :post]
        match :depublish, on: :member, via: [:get, :post]
        resources :columns, only: %i[index create] do
          post :reorder, on: :collection
        end
        match :copy, on: :member, via: [:get, :post]
      end
      resources :externals, concerns: :deletion
      resources :categories, concerns: :deletion
      resources :purposes, concerns: :deletion
    end
    get "/search_approvers" => "search_approvers#index"

    namespace "apis" do
      get "delegatees" => "delegatees#index"
      get "form_categories" => "form_categories#index"
      get "form_purposes" => "form_purposes#index"
      resources :user_superiors, only: %i[show]
    end
    namespace :frames do
      resources :approvers, only: %i[show update] do
        post :cancel, on: :member
        post :reroute, on: :member
      end
      resources :inspections, only: %i[update]
      resources :circulations, only: %i[update]
      resources :destination_states, only: %i[show update]
      resources :categories, path: ':state/:mode/categories', only: %i[index]
    end
  end
end
