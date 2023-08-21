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
    resources :forms, concerns: [:deletion] do
      match :copy_year, on: :collection, via: %i[get post]
      resources :columns, concerns: :deletion
    end
    scope(path: ':year_month') do
      resources :reports, concerns: :deletion do
        get :print, on: :member
        post :download_all_comments, on: :collection
      end
      resources :reports, path: ':form_id', only: [:new, :create], as: 'form_reports'
      resources :user_reports, path: 'users/:user/reports', concerns: [:deletion, :export] do
        get :print, on: :collection
      end
      resources :user_reports, path: 'users/:user/reports/form/:form_id', only: [:new, :create], as: 'form_user_reports'
      namespace :user_reports, path: 'users/:user/reports' do
        resources :comments, path: ':report/:column/comments', concerns: [:deletion]
      end
      resources :group_share_reports, path: 'groups/:group/share_reports', only: [:index], concerns: [:export] do
        get :print, on: :collection
      end
    end
    scope(path: ':ymd') do
      resources :group_reports, path: 'groups/:group/reports', concerns: [:deletion, :download_all] do
        get :print, on: :collection
      end
      resources :group_reports, path: 'groups/:group/reports/form/:form_id', only: [:new, :create], as: 'form_group_reports'
      namespace :group_reports, path: 'groups/:group/reports' do
        resources :comments, path: ':report/:column/comments', concerns: [:deletion]
      end
    end
  end
end
