class Opendata::Agents::Parts::Dataset::DatasetCounterController < ApplicationController
  include Cms::PartFilter::View
  helper Opendata::UrlHelper

  public

  def index
    @datasets = Opendata::Dataset.site(@cur_site).and_public
    @tags = @datasets.aggregate_array :tags
    @dataset_groups = Opendata::DatasetGroup.site(@cur_site).and_public
  end
end
