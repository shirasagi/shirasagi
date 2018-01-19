SS::Application.routes.draw do
  Gws::Attendance::Initializer

  gws 'attendance' do
    resources :time_cards
  end
end
