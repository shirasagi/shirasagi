#frozen_string_literal: true

class Cms::Frames::TempFiles::FilesController < ApplicationController
  include Cms::BaseFilter

  model SS::File

  layout 'ss/item_frame'

  before_action :set_search_params

  helper_method :cur_node, :items

  private

  def set_search_params
    @s ||= begin
      s = Cms::TempFileSearchParam.new(cur_site: @cur_site, cur_user: @cur_user, cur_node: cur_node)
      if params.key?(:s)
        s.attributes = params[:s].permit(:node, :keyword, types: [])
      else
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

  # no bound
  def base_items
    set_search_params

    @base_items ||= begin
      criteria = Cms::TempFile.site(@cur_site)
      criteria = criteria.exists(node_id: false)
      criteria = criteria.allow(:read, @cur_user)
      criteria
    end
  end

  # # bounded to node
  # def items
  #   @items ||= begin
  #     criteria = Cms::TempFile.site(@cur_site)
  #     criteria = criteria.node(@cur_node)
  #     criteria = criteria.allow(:read, @cur_user)
  #     criteria
  #   end
  # end

  # # cms file
  # def items
  #   @items ||= begin
  #     criteria = Cms::File.site(@cur_site)
  #     criteria = criteria.allow(:read, @cur_user)
  #     criteria
  #   end
  # end

  # # user file
  # def items
  #   @items ||= begin
  #     criteria = SS::UserFile.user(@cur_user)
  #     criteria
  #   end
  # end

  def items
    @items ||= base_items.reorder(filename: 1).page(params[:page]).per(20)
  end

  public

  def index
    render
  end
end
