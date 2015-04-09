class Opendata::Datasets::SearchController < ApplicationController
  include Cms::ApiFilter

  model Opendata::Dataset
end
