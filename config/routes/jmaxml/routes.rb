SS::Application.routes.draw do

  # Jmaxml::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    match :import, via: [:get, :post], on: :collection
  end

  namespace "jmaxml", path: ".s:site/rss" do
    namespace "apis" do
      get "quake_regions" => "quake_regions#index"
      get "tsunami_regions" => "tsunami_regions#index"
      get "forecast_regions" => "forecast_regions#index"
      get "water_level_stations" => "water_level_stations#index"
    end
  end

  content "jmaxml" do
    resources :quake_regions, concerns: [:deletion, :download, :import]
    resources :tsunami_regions, concerns: [:deletion, :download, :import]
    resources :forecast_regions, concerns: [:deletion, :download, :import]
    resources :water_level_stations, concerns: [:deletion, :download, :import]
    resources :filters, concerns: [:deletion]
    scope module: :trigger, as: :trigger do
      resources :quake_intensity_flashes, path: 'triggers/quake_intensity_flashes', concerns: [:deletion]
      resources :quake_infos, path: 'triggers/quake_infos', concerns: [:deletion]
      resources :tsunami_alerts, path: 'triggers/tsunami_alerts', concerns: [:deletion]
      resources :tsunami_infos, path: 'triggers/tsunami_infos', concerns: [:deletion]
      resources :flood_forecasts, path: 'triggers/flood_forecasts', concerns: [:deletion]
      resources :weather_alerts, path: 'triggers/weather_alerts', concerns: [:deletion]
      resources :landslide_infos, path: 'triggers/landslide_infos', concerns: [:deletion]
      resources :flood_forecasts, path: 'triggers/flood_forecasts', concerns: [:deletion]
      resources :volcano_flashes, path: 'triggers/volcano_flashes', concerns: [:deletion]
      resources :ash_fall_forecasts, path: 'triggers/ash_fall_forecasts', concerns: [:deletion]
      resources :tornado_alerts, path: 'triggers/tornado_alerts', concerns: [:deletion]
      # put base at last
      resources :bases, path: 'triggers', concerns: [:deletion], only: [:index, :show, :new, :create, :edit, :delete]
    end
    scope module: :action, as: :action do
      resources :switch_urgencies, path: 'actions/switch_urgencies', concerns: [:deletion]
      resources :publish_pages, path: 'actions/publish_pages', concerns: [:deletion]
      resources :send_mails, path: 'actions/send_mails', concerns: [:deletion]
      # put base at last
      resources :bases, path: 'actions', concerns: [:deletion], only: [:index, :show, :new, :create, :edit, :delete]
    end
  end
end
