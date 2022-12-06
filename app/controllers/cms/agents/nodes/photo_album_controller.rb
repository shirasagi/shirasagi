class Cms::Agents::Nodes::PhotoAlbumController < ApplicationController
  include Cms::NodeFilter::View
  include Cms::ForMemberFilter::Node
  helper Cms::ListHelper

  before_action :becomes_with_route_node
  ALLOWED_EXTS = %w(gif png jpg jpeg bmp).freeze

  class PhotoAlbumSearchService < Cms::FileSearchService
    attr_accessor :cur_date, :condition_hash, :sort

    private

    # override Cms::FileSearchService#stage_search
    def stage_search
      @stages << { "$match" => { filename: { "$in" => ALLOWED_EXTS.map{ |ext| %r{#{ext}$}i } } } }

      page_condition = Cms::Page.and_public_selector(cur_date)
      page_condition[:site_id] = cur_site.id
      page_condition.merge(condition_hash) if condition_hash.present?

      @stages << { "$match" => { page: { "$elemMatch" => page_condition } } }
    end

    # override Cms::FileSearchService#stage_lookup_pages
    # "$facet" は 各ステージの結果を BSON Document として保存するが、この BSON Document が 16MB を超える場合、エラーが発生する。
    # 特に画像の data url が埋め込まれている際に、BSON Document が 16MB を超過しないように html, contains_urls を除外する。
    def stage_lookup_pages
      super
      @stages << { "$project" => { "page.html" => 0, "page.column_values" => 0, "page.contains_urls" => 0 } }
    end

    # override Cms::FileSearchService#stage_permissions
    def stage_permissions
      # nothing
    end

    # override Cms::FileSearchService#stage_pagination
    def stage_pagination
      @stages << { "$sort" => sort_hash }
      super
    end

    def sort_hash
      return { "page.released" => -1 } if sort.blank?
      { "page.#{sort.sub(/ .*/, "")}" => (/-1$/.match?(sort) ? -1 : 1), name: 1 }
    end
  end

  private

  def becomes_with_route_node
    @cur_parent = @cur_node.parent
  end

  public

  def index
    if @cur_node.conditions.present?
      condition_hash = @cur_node.condition_hash
    else
      condition_hash = @cur_parent.try(:condition_hash)
      condition_hash ||= @cur_node.condition_hash
    end

    service = PhotoAlbumSearchService.new(cur_site: @cur_site, cur_user: @cur_user)
    service.cur_date = @cur_date
    service.condition_hash = condition_hash
    service.page = params[:page].try { |page| page.to_s.numeric? ? page.to_s.to_i - 1 : nil } || 0
    service.limit = @cur_node.limit if @cur_node.limit > 0
    service.sort = @cur_node.sort

    @items = service.call
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
