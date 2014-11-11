class Opendata::DatasetGroups::SearchController < ApplicationController
  include Cms::SearchFilter

  model Opendata::DatasetGroup
end
