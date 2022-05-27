Rails.application.routes.draw do

  Map::Initializer

  part "map" do
    get "geolocation_page" => "public#index", cell: "parts/geolocation_page"
  end
end
