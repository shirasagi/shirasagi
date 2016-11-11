SS::Application.routes.draw do

  Rss::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    match :import, via: [:get, :post], on: :collection
  end

  namespace "rss", path: ".s:site/rss" do
    namespace "apis" do
      namespace 'weather_xml' do
        get "quake_regions" => "quake_regions#index"
        get "tsunami_regions" => "tsunami_regions#index"
        get "forecast_regions" => "forecast_regions#index"
        get "flood_regions" => "flood_regions#index"
      end
    end
  end

  content "rss" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :import]
    resources :weather_xmls, concerns: [:deletion]
    namespace 'weather_xml' do
      resources :quake_regions, concerns: [:deletion, :download, :import]
      resources :tsunami_regions, concerns: [:deletion, :download, :import]
      resources :forecast_regions, concerns: [:deletion, :download, :import]
      resources :flood_regions, concerns: [:deletion, :download, :import]
      resources :filters, concerns: [:deletion]
      scope module: :trigger, as: :trigger do
        resources :bases, path: 'triggers', concerns: [:deletion], only: [:index, :show, :new, :create, :edit, :delete]
        resources :quake_intensity_flashes, path: 'triggers/quake_intensity_flashes', concerns: [:deletion]
        resources :tsunami_alerts, path: 'triggers/tsunami_alerts', concerns: [:deletion]
        resources :flood_forecasts, path: 'triggers/flood_forecasts', concerns: [:deletion]
        resources :weather_alerts, path: 'triggers/weather_alerts', concerns: [:deletion]
        resources :landslide_infos, path: 'triggers/landslide_infos', concerns: [:deletion]
        resources :flood_forecasts, path: 'triggers/flood_forecasts', concerns: [:deletion]
      end
      scope module: :action, as: :action do
        resources :bases, path: 'actions', concerns: [:deletion], only: [:index, :show, :new, :create, :edit, :delete]
        resources :change_urgencies, path: 'actions/change_urgencies', concerns: [:deletion]
        resources :publish_pages, path: 'actions/publish_pages', concerns: [:deletion]
        resources :send_mails, path: 'actions/send_mails', concerns: [:deletion]
      end
    end
  end

  node "rss" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"

    get "weather_xml/(index.:format)" => "public#index", cell: "nodes/weather_xml"
    get "weather_xml/subscriber(.:format)" => "public#confirmation", cell: "nodes/weather_xml"
    post "weather_xml/subscriber(.:format)" => "public#subscription", cell: "nodes/weather_xml"
  end

  page "rss" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end
end
