Rails.application.routes.draw do
  Gws::DailyReport::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    get :download, on: :collection
  end

  concern :download_all do
    match :download_all, on: :collection, via: %i[get post]
  end

  gws "daily_report" do
    get '/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}/reports" }, as: :main
    scope(path: ':year_month') do
      resources :reports, concerns: :deletion do
        get :print, on: :member
        post :download_comment, on: :member
        post :download_attachment, on: :member
        post :download_all_comments, on: :collection
        post :download_all_attachments, on: :collection
      end
      resources :reports, path: ':form_id', only: [:new, :create], as: 'form_reports'
      resources :user_reports, path: 'users/:user/reports', concerns: [:deletion, :export] do
        get :print, on: :collection
        match :comment, path: ':column/comment', on: :member, via: %i[get post]
      end
      resources :user_reports, path: 'users/:user/:form_id', only: [:new, :create], as: 'form_user_reports'
    end
    scope(path: ':ymd') do
      resources :group_reports, path: 'groups/:group/reports', concerns: [:deletion, :download_all] do
        get :print, on: :collection
        match :comment, path: ':column/comment', on: :member, via: %i[get post]
      end
      resources :group_reports, path: 'groups/:group/:form_id', only: [:new, :create], as: 'form_group_reports'
    end
    resources :forms, concerns: :deletion do
      resources :columns, concerns: :deletion
    end
  end
end
