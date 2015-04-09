class Opendata::DatasetGroups::SearchController < ApplicationController
  include Cms::ApiFilter

  model Opendata::DatasetGroup
end
