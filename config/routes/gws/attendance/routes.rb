SS::Application.routes.draw do
  Gws::Attendance::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  gws 'attendance' do
    get '/' => redirect { |p, req| "#{req.path}/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main
    resources :time_cards, path: 'time_cards/:year_month', only: %i[index] do
      match :download, on: :collection, via: %i[get post]
      get :print, on: :collection
      post :enter, on: :collection
      post :leave, on: :collection
      post :break_enter, path: 'break_enter:index', on: :collection
      post :break_leave, path: 'break_leave:index', on: :collection
      match :memo, path: ':day/memo', on: :collection, via: %i[get post]
      match :time, path: ':day/:type', on: :collection, via: %i[get post]
    end

    namespace 'management' do
      get '/' => redirect { |p, req| "#{req.path}/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main
      resources :time_cards, path: 'time_cards/:year_month', except: %i[new create edit update], concerns: %i[deletion] do
        match :memo, path: ':day/memo', on: :member, via: %i[get post]
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
