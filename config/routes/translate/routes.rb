Rails.application.routes.draw do

  Translate::Initializer

  part "translate" do
    get "tool" => "public#index", cell: "parts/tool"
  end
end
