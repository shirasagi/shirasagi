Rails.application.routes.draw do
  Gws::Affair::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
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

  concern :approve_all do
    post :approve_all, on: :collection, path: 'approve_all'
  end

  concern :plans do
    get :events, on: :collection
    get :print, on: :collection
    get :popup, on: :member
    get :copy, on: :member
    match :soft_delete, on: :member, via: [:get, :post]
  end

  concern :export do
    get :download, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :export_yearly do
    get :download_yearly, on: :collection
    post :download_yearly, on: :collection
  end

  concern :import_member do
    get :download_member, on: :collection
    get :import_member, on: :collection
    post :import_member, on: :collection
  end

  concern :import_group do
    get :download_group, on: :collection
    get :import_group, on: :collection
    post :import_group, on: :collection
  end

  gws "affair" do
    get '/' => redirect { |p, req| "#{req.path}/attendance/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main
    resources :duty_calendars, concerns: :deletion
    resources :duty_notices, concerns: :deletion
    resources :special_leaves, concerns: [:deletion, :export]
    resources :capital_years, concerns: :deletion
    scope 'year/:year' do
      resources :capitals, concerns: [:deletion, :export, :import_member, :import_group], as: :capitals
      resources :leave_settings, concerns: [:deletion, :export, :export_yearly, :import_member]
    end

    namespace "overtime" do
      resources :files, path: 'files/:state', concerns: [:deletion, :workflow, :approve_all]
      get "aggregate" => "aggregate#index"
      get "aggregate/show/:group_id/:uid" => "aggregate#show", as: :show_aggregate
      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      get "/wizard/:id/approveByDelegatee" => "wizard#approve_by_delegatee", as: "approve_by_delegatee"
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard

      resources :results, only: [:edit, :update] do
        post :close, on: :member
      end

      namespace 'management' do
        get "aggregate" => redirect { |p, req| "#{req.path}/users" }

        namespace 'aggregate' do
          # aggregate/users
          get "users" => "users#index", as: :users_main
          get "users/total/f:fiscal_year/:month" => "users#total", as: :users_total
          get "users/under/f:fiscal_year/:month" => "users#under", as: :users_under
          get "users/over/f:fiscal_year/:month" => "users#over", as: :users_over
          get "users/download/total/f:fiscal_year/:month" => "users#download_total", as: :users_download_total
          get "users/download/under/f:fiscal_year/:month" => "users#download_under", as: :users_download_under
          get "users/download/over/f:fiscal_year/:month" => "users#download_over", as: :users_download_over
          post "users/download/total/f:fiscal_year/:month" => "users#download_total"
          post "users/download/under/f:fiscal_year/:month" => "users#download_under"
          post "users/download/over/f:fiscal_year/:month" => "users#download_over"

          # aggregate/capitals
          get "capitals" => "capitals#index", as: :capitals_main
          get "capitals/yearly/f:fiscal_year" => "capitals#yearly", as: :capitals_yearly
          get "capitals/groups/f:fiscal_year/:month/:group" => "capitals#groups", as: :capitals_groups
          get "capitals/users/f:fiscal_year/:month/:group" => "capitals#users", as: :capitals_users
          get "capitals/download/yearly/f:fiscal_year" => "capitals#download_yearly", as: :capitals_download_yearly
          get "capitals/download/groups/f:fiscal_year/:month/:group" => "capitals#download_groups", as: :capitals_download_groups
          get "capitals/download/users/f:fiscal_year/:month/:group" => "capitals#download_users", as: :capitals_download_users
          post "capitals/download/yearly/f:fiscal_year" => "capitals#download_yearly"
          post "capitals/download/groups/f:fiscal_year/:month/:group" => "capitals#download_groups"
          post "capitals/download/users/f:fiscal_year/:month/:group" => "capitals#download_users"

          # aggregate/search_groups
          get "search_groups" => "search_groups#index", as: :search_groups_main
          get "search_groups/f:fiscal_year/:month" => "search_groups#search", as: :search_groups_search
          get "search_groups/results/f:fiscal_year/:month" => "search_groups#results", as: :search_groups_results
          get "search_groups/download/f:fiscal_year/:month" => "search_groups#download", as: :search_groups_download
          post "search_groups/download/f:fiscal_year/:month" => "search_groups#download"

          # aggregate/search_users
          get "search_users" => "search_users#index", as: :search_users_main
          get "search_users/f:fiscal_year/:month" => "search_users#search", as: :search_users_search
          get "search_users/results/f:fiscal_year/:month" => "search_users#results", as: :search_users_results
          get "search_users/download/f:fiscal_year/:month" => "search_users#download", as: :search_users_download
          post "search_users/download/f:fiscal_year/:month" => "search_users#download"

          # aggregate/rkk
          get "rkk" => "rkk#index", as: :rkk_main
          get "rkk/download/f:fiscal_year/:month" => "rkk#download", as: :rkk_download
          post "rkk/download/f:fiscal_year/:month" => "rkk#download"
        end
      end

      namespace "apis" do
        get "week_in_files/:uid/:year_month_day" => "files#week_in", as: :files_week_in
        get "week_out_files/:uid/:year_month_day" => "files#week_out", as: :files_week_out
        get "holiday_files/:uid/:year_month_day" => "files#holiday", as: :files_holiday

        get "capitals" => "capitals#index", as: :capitals
        get "capitals/effective/:uid" => "capitals#effective", as: :effective_capital

        get "check_holiday/:uid/:year_month_day" => "check_holiday#index", as: :check_holiday
      end
    end

    namespace "leave" do
      resources :files, path: 'files/:state', concerns: [:deletion, :workflow, :approve_all]
      get "aggregate" => "aggregate#index"
      get "aggregate/show/:group_id/:uid" => "aggregate#show", as: :show_aggregate
      get "aggregate/download/:group_id" => "aggregate#download", as: :download_aggregate
      post "aggregate/download/:group_id" => "aggregate#download"

      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      get "/wizard/:id/approveByDelegatee" => "wizard#approve_by_delegatee", as: "approve_by_delegatee"
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard
      namespace "apis" do
        get "files/:id" => "files#show", as: :file
        get "special_leaves/:uid" => "special_leaves#index", as: :special_leaves
        get "annual_leaves/:uid/:year_month_day" => "annual_leaves#index", as: :annual_leaves
      end
    end

    namespace "working_time" do
      namespace 'management' do
        get "aggregate" => redirect { |p, req| "#{req.path}/default" }, as: :aggregate_main
        get "aggregate/:duty_type" => "aggregate#index", as: :aggregate
        get "aggregate/:duty_type/download" => "aggregate#download", as: :download_aggregate
        post "aggregate/:duty_type/download" => "aggregate#download"
      end
    end

    get '/shift_work/' => redirect { |p, req| "#{req.path}/calendar/" }, as: :shift_work_main
    namespace "shift_work" do
      get '/calendar/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :calendar_main
      get '/calendar/:year_month' => 'calendar#index', as: :calendar
      get '/calendar/:year_month/:day/:user/shift_record' => 'calendar#shift_record'
      post '/calendar/:year_month/:day/:user/shift_record' => 'calendar#shift_record'

      resources :shift_calendars, only: [:index]
      resources :shift_calendars, concerns: :deletion, except: [:index], path: "shift_calendars/g:group_id/u:user" do
        get '/shift_records/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y/%m')}" }, as: :shift_record_main
        resources :shift_records, path: 'shift_records/:year/:month', concerns: [:deletion, :export], year: /(\d{4}|ID)/, month: /(\d{2}|ID)/
      end
    end

    resources :duty_hours, concerns: :deletion
    resources :holiday_calendars, concerns: :deletion do
      resources :holidays, concerns: :deletion, path: "holidays/:year" do
        get :download, on: :collection
        match :import, on: :collection, via: %i[get post]
      end
    end

    namespace "apis" do
      namespace "overtime" do
        resources :results, only: [:edit, :update]
      end
      get "duty_hours" => "duty_hours#index"
      get "duty_notices" => "duty_notices#index"
      get "holiday_calendars" => "holiday_calendars#index"
      get "result_groups/f:fiscal_year/:month" => "result_groups#index", as: :result_groups
    end

    namespace "attendance" do
      get '/time_cards/' => "time_cards#main", as: :time_card_main
      #get '/time_cards/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :time_card_main
      resources :time_cards, path: 'time_cards/:year_month', only: %i[index] do
        match :download, on: :collection, via: %i[get post]
        get :print, on: :collection
        post :enter, on: :collection
        post :leave, on: :collection
        post :leave, path: 'leave:date', on: :collection
        post :break_enter, path: 'break_enter:index', on: :collection
        post :break_leave, path: 'break_leave:index', on: :collection
        match :memo, path: ':day/memo', on: :collection, via: %i[get post]
        match :working_time, path: ':day/working_time', on: :collection, via: %i[get post]
        match :time, path: ':day/:type', on: :collection, via: %i[get post]
      end
      namespace "time_card" do
        get 'groups' => "groups#main", as: :groups_main
        get 'groups/:year_month/:day' => "groups#index", as: :groups
      end

      namespace 'management' do
        get '/' => redirect { |p, req| "#{req.path}/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main
        get '/time_cards/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :time_card_main
        resources :time_cards, path: 'time_cards/:year_month', except: %i[new create edit update], concerns: %i[deletion] do
          match :memo, path: ':day/memo', on: :member, via: %i[get post]
          match :working_time, path: ':day/working_time', on: :member, via: %i[get post]
          match :time, path: ':day/:type', on: :member, via: %i[get post]
          match :download, on: :collection, via: %i[get post]
          match :lock, on: :collection, via: %i[get post]
          match :unlock, on: :collection, via: %i[get post]
        end
      end

      namespace 'apis' do
        namespace 'management' do
          get 'users' => 'users#index'
        end
      end
    end
  end
end
