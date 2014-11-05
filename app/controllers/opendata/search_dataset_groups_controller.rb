class Opendata::SearchDatasetGroupsController < ApplicationController
  include Cms::SearchFilter

  model Opendata::DatasetGroup
end
