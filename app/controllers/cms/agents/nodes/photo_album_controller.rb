class Cms::Agents::Nodes::PhotoAlbumController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  before_action :becomes_with_route_node
  ALLOWED_EXTS = %w(gif png jpg jpeg bmp).freeze

  private
    def becomes_with_route_node
      @cur_node = @cur_node.becomes_with_route
      @cur_parent = @cur_node.parent.try(:becomes_with_route)
    end

    def file_id_name_url
      if @cur_node.conditions.present?
        condition_hash = @cur_node.condition_hash
      else
        condition_hash = @cur_parent.try(:condition_hash)
        condition_hash ||= @cur_node.condition_hash
      end
      box=[]
      Cms::Page.site(@cur_site).
        and_public(@cur_date).
        where(condition_hash).
        order_by(@cur_node.sort_hash).
        excludes(:file_ids => []).
        map{ |i| [i.file_ids, i.name, i.url] }.
        each { |j| j[0].each{|k| box << [k, j[1], j[2]]}}
      box
    end

  public
    def index
      box = []
      file_id_name_url.each do |i|
        if SS::File.any_in(filename: ALLOWED_EXTS.map{|ext| %r{#{ext}$}i}, id: i[0]).present?
          box << [SS::File.find(i[0]), i[1], i[2]]
        end
      end

      @items = Kaminari.paginate_array(box).page(params[:page]).per(@cur_node.limit)
      render_with_pagination @items
    end

    # def rss
    #   @items = pages.
    #     order_by(publushed: -1).
    #     per(@cur_node.limit)
    #
    #   render_rss @cur_node, @items
    # end
end
