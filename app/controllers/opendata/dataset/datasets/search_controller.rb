class Opendata::Dataset::Datasets::SearchController < ApplicationController
  include Cms::ApiFilter

  model Opendata::Dataset
end
