Rails.application.routes.draw do
  Gws::Affair2::Initializer

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

  gws "affair2" do
    get "/" => "main#index", as: :main

    # attendance
    namespace "attendance" do
      get '/' => "main#index", as: :main

      # time_cards
      get '/time_cards/' => "main#index", as: :time_card_main
      resources :time_cards, path: 'time_cards/:year_month', only: [:index, :create] do
        get :setting, on: :collection
        match :download, on: :collection, via: %i[get post]
        get :print, on: :collection
      end

      # groups
      get 'groups' => "groups#main", as: :groups_main
      get 'groups/:group/:year_month/:day' => "groups#index", as: :groups
    end

    # time_card_forms
    namespace :time_card_forms, path: 'time_card_forms/:id' do
      # enter
      get 'enter/:day' => "enter#index", as: :edit_enter
      post 'enter/:day' => "enter#update"
      post 'enter/:day/punch' => "enter#punch", as: :punch_enter
      # leave
      get 'leave/:day' => "leave#index", as: :edit_leave
      post 'leave/:day' => "leave#update"
      post 'leave/:day/punch' => "leave#punch", as: :punch_leave
      # memo
      get 'memo/:day' => "memo#index", as: :edit_memo
      post 'memo/:day' => "memo#update"
      # break_minutes
      get 'break_minutes/:day' => "break_minutes#index", as: :edit_break_minutes
      post 'break_minutes/:day' => "break_minutes#update"
      # regular_holiday
      get 'regular_holiday/:day' => "regular_holiday#index", as: :edit_regular_holiday
      post 'regular_holiday/:day' => "regular_holiday#update"
      # regular_start
      get 'regular_start/:day' => "regular_start#index", as: :edit_regular_start
      post 'regular_start/:day' => "regular_start#update"
      # regular_close
      get 'regular_close/:day' => "regular_close#index", as: :edit_regular_close
      post 'regular_close/:day' => "regular_close#update"
      # regular_break_minutes
      get 'regular_break_minutes/:day' => "regular_break_minutes#index", as: :edit_regular_break_minutes
      post 'regular_break_minutes/:day' => "regular_break_minutes#update"
      # regular_record
      get 'regular_record' => "regular_record#index", as: :import_regular_record
      get 'regular_record/download' => "regular_record#download", as: :download_regular_record
      post 'regular_record' => "regular_record#update"
      # overtime_records
      get 'overtime_records/:day' => "overtime_records#index", as: :edit_overtime_records
      post 'overtime_records/:day' => "overtime_records#update"
      # leave_records
      get 'leave_records/:day' => "leave_records#index", as: :edit_leave_records
    end

    # overtime
    namespace "overtime" do
      get '/' => "main#index", as: :main

      get '/workday_files/' => redirect { |p, req| "#{req.path}/mine" }, as: :workday_files_main
      resources :workday_files, path: 'workday_files/:state', defaults: { state: 'mine' }, concerns: [:deletion, :workflow]

      get '/holiday_files/' => redirect { |p, req| "#{req.path}/mine" }, as: :holiday_files_main
      resources :holiday_files, path: 'holiday_files/:state', defaults: { state: 'mine' }, concerns: [:deletion, :workflow]

      resource :record, path: 'record/:file_id' do
        get :confirmed, on: :collection
      end

      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      get "/wizard/:id/approveByDelegatee" => "wizard#approve_by_delegatee", as: "approve_by_delegatee"
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard

      resources :achieve, path: 'achieve/:group/:year_month', only: [:index, :show]
    end

    # leave
    namespace "leave" do
      get '/files/' => redirect { |p, req| "#{req.path}/mine" }, as: :files_main
      resources :files, path: 'files/:state', defaults: { state: 'mine' }, concerns: [:deletion, :workflow]

      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      get "/wizard/:id/approveByDelegatee" => "wizard#approve_by_delegatee", as: "approve_by_delegatee"
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard

      resources :achieve, path: 'achieve/:group/:year_month', only: [:index, :show]
    end

    # management
    namespace "management" do
      get '/' => "main#index", as: :main

      # users time_cards
      get '/time_cards/' => "time_card_main#index", as: :time_card_main
      resources :time_cards, path: 'time_cards/:group/:year_month', only: [:index, :show, :destroy], concerns: [:deletion] do
        get :setting, on: :member
        match :lock, on: :collection, via: %i[get post]
        match :unlock, on: :collection, via: %i[get post]
      end

      get '/aggregations/' => "aggregation_main#index", as: :aggregation_main
      get '/aggregations/:employee_type' => "aggregation_main#index", as: :aggregation_employee_type_main
      resources :aggregations, path: '/aggregations/:employee_type/:unit/:form/:year_month', only: [:index] do
        match :download, on: :collection, via: %i[get post]
      end
    end

    # admin
    namespace "admin" do
      get '/' => "main#index", as: :main

      # attendance_settings
      resources :users, only: [:index] do
        resources :attendance_settings, concerns: [:deletion]
        match :download_all, on: :collection, via: %i[get post]
        match :download_no_setting, on: :collection, via: %i[get post]
        match :import, on: :collection, via: %i[get post]
      end

      # paid_leave_settings
      get 'years' => "years#index", as: :years
      scope "years/:year" do
        resources :paid_leave_settings, concerns: [:deletion] do
          match :import, on: :collection, via: %i[get post]
          #match :download, on: :collection, via: %i[get post]
          get :download_template, on: :collection
          match :download_remind, on: :collection, via: %i[get post]
        end
      end

      # duty_settings
      resources :duty_settings, concerns: [:deletion]

      # leave_settings
      resources :leave_settings, concerns: [:deletion]

      # special_leave
      resources :special_leave, concerns: [:deletion]

      # special_holidays
      get 'special_holidays' => "special_holidays#main", as: :special_holidays_main
      resources :special_holidays, path: 'special_holidays/:year', concerns: [:deletion]

      # duty_notices
      resources :duty_notices, concerns: [:deletion]
    end

    namespace 'apis' do
      get 'attendance_settings/:year' => 'attendance_settings#index', as: :attendance_settings
      get 'paid_leave/:user/:date' => 'paid_leave#index', as: :paid_leave

      get 'special_leave' => 'special_leave#index'
      get 'duty_settings' => 'duty_settings#index'
      get 'duty_notices' => 'duty_notices#index'
    end
  end
end
