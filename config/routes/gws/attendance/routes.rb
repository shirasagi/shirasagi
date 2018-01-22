SS::Application.routes.draw do
  Gws::Attendance::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'attendance' do
    get 'time_cards' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :time_cards_main
    resources :time_cards, path: 'time_cards/:year_month', only: %i[index new create] do
      get :download, on: :collection
      post :enter, on: :collection
      post :leave, on: :collection
    end
  end
end
