class Cms::Node::ImageResizesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::ImageResize

  private

  def fix_params
    { cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_item
    @item = @model.site(@cur_site).node(@cur_node).first
    @item ||= @model.new
    @item.attributes = fix_params
    @item
  end
end
