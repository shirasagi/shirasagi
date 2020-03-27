class Opendata::Agents::Nodes::Dataset::ResourceController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::Dataset::ResourceFilter
  include Opendata::UrlHelper
  include SS::AuthFilter

  model Opendata::Resource

  private

  def set_item
    @item = @dataset.resources.find_by id: params[:id]
  end
end
