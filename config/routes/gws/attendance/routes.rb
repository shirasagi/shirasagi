SS::Application.routes.draw do
  Gws::Attendance::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'attendance' do
    get '/' => redirect { |p, req| "#{req.path}/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main
    resources :time_cards, path: 'time_cards/:year_month', only: %i[index] do
      get :download, on: :collection
      post :enter, on: :collection
      post :leave, on: :collection
      post :break_enter, path: 'break_enter:index', on: :collection
      post :break_leave, path: 'break_leave:index', on: :collection
      match :memo, path: ':day/memo', on: :collection, via: %i[get post]
      match :time, path: ':day/:type', on: :collection, via: %i[get post]
    end

    namespace 'management' do
      get '/' => redirect { |p, req| "#{req.path}/time_cards" }, as: :main
      resources :time_cards, concerns: [:deletion] do
        get :download, on: :collection
      end
    end
  end
end
