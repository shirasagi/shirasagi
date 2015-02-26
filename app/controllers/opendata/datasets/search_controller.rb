class Opendata::Datasets::SearchController < ApplicationController
  include Cms::SearchFilter

  model Opendata::Dataset
end
