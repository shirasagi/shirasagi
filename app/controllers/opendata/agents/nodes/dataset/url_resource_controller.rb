class Opendata::Agents::Nodes::Dataset::UrlResourceController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::Dataset::ResourceFilter
  include Opendata::UrlHelper
  include SS::AuthFilter

  model Opendata::UrlResource

  private

  def set_item
    @item = @dataset.url_resources.find_by id: params[:id]
  end
end
