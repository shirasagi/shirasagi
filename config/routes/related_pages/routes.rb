# coding: utf-8
SS::Application.routes.draw do

  RelatedPages::Initializer

  namespace "related_pages", path: ".:host/related/pages" do
    get "/" => "search#index"
    get "/search" => "search#search"
  end
end
