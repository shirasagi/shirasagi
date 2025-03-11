#frozen_string_literal: true

class Cms::Frames::TempFiles::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model SS::File

  layout 'ss/item_frame'

  before_action :set_search_params

  helper_method :cur_node, :items

  private

  def set_search_params
    @s ||= begin
      s = Cms::TempFileSearchParam.new(cur_site: @cur_site, cur_user: @cur_user, cur_node: cur_node)
      if params.key?(:s)
        s.attributes = params[:s].permit(:node, :keyword, :node_bound, types: [])
      end
      if s.types.blank? && s.node_bound.blank?
        s.types = %w(temp_file)
        s.node_bound = "current"
      end
      s.validate
      s
    end
  end

  def cur_node
    return @cur_node if instance_variable_defined?(:@cur_node)

    cid = params[:cid].to_s
    if cid.blank?
      @cur_node = nil
      return @cur_node
    end

    @cur_node = Cms::Node.site(@cur_site).find(cid)
  end

  def base_items
    set_search_params
    @base_items ||= @s.query(SS::File, SS::File.unscoped)
  end

  def items
    @items ||= base_items.reorder(filename: 1).page(params[:page]).per(20)
  end

  def crud_redirect_url
    url_for(action: :index, cid: cur_node, s: params[:s].try(:to_unsafe_h))
  end

  def set_item
    @item ||= begin
      item = SS::File.find(params[:id])
      item = item.becomes_with_model
      if item.is_a?(SS::TempFile)
        item = item.becomes_with(Cms::TempFile)
      end
      @model = item.class
      item
    end
  end

  public

  def index
    render
  end

  def select
    set_item
    if !@item.is_a?(SS::TempFile) && !@item.is_a?(Cms::TempFile)
      @item = @item.copy(
        cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node
      )
    end
    render layout: false
  end
end
