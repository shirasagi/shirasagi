class Cms::Agents::Nodes::SiteSearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  before_action :set_setting
  before_action :save_search_history

  model Cms::Elasticsearch::Searcher

  private

  def set_setting
    @setting ||= begin
      setting_model = Cms::Elasticsearch::Setting::Page
      setting_model.new(cur_site: @cur_site, cur_user: @cur_user)
    end
  end

  def save_search_history
    return if search_query.blank?

    query = search_query
    query[:keyword] = query[:keyword].to_s.strip.gsub(/　/, " ")
    return if query.values.flatten.reject(&:blank?).blank?

    history_log = Cms::SiteSearch::History::Log.new(
      site: @cur_site,
      query: query.to_h,
      remote_addr: remote_addr,
      user_agent: request.user_agent
    )
    history_log.save
  end

  def fix_params
    { setting: @setting, aggregate_size: SS.config.cms.elasticsearch['aggregate_size'] }
  end

  def permit_fields
    [:keyword, :target, :category_name, category_names: []]
  end

  def get_params
    if params[:s].present?
      params.require(:s).permit(permit_fields).merge(fix_params)
    else
      fix_params
    end
  end

  def search_query
    return if params[:s].blank?

    params.require(:s).permit(permit_fields)
  end

  public

  def index
    @s = @item = @model.new(get_params)
    @aggregate_result = @model.new(fix_params).search

    return if search_query.blank? || search_query.values.flatten.reject(&:blank?).blank?

    if @cur_site.elasticsearch_sites.present?
      @s.index = @cur_site.elasticsearch_sites.collect { |site| "s#{site.id}" }.join(",")
    end

    if params[:target] == 'outside' && @cur_site.elasticsearch_outside_enabled?
      indexes = @cur_site.elasticsearch_indexes.presence || [@s.index, "fess.search"]
      @s.index = [indexes].flatten.join(",")
    end

    @s.field_name = %w(text_index content title)
    @s.from = (params[:page].to_i - 1) * @s.size if params[:page].present?
    @result = @s.search
  end

  def categories
    @s = @item = @model.new(get_params)

    if @cur_node.st_categories.present?
      @items = @cur_node.st_categories
    else
      @aggregate_result = @s.search
    end

    @cur_node.layout_id = nil
    render layout: 'cms/ajax'
  end
end
