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
    keyword = get_params[:keyword].to_s.strip.gsub(/　/, " ")
    return if keyword.blank?

    query = { keyword: keyword }
    query[:category_name] = get_params[:category_name] if get_params[:category_name].present?

    history_log = Cms::SiteSearch::History::Log.new(
      site: @cur_site,
      query: query,
      remote_addr: remote_addr,
      user_agent: request.user_agent
    )
    history_log.save
  end

  def fix_params
    { setting: @setting }
  end

  def permit_fields
    [:keyword, :target, :category_name]
  end

  def get_params
    if params[:s].present?
      params.require(:s).permit(permit_fields).merge(fix_params)
    else
      fix_params
    end
  end

  public

  def index
    @s = @item = @model.new(get_params)
    @aggregate_result = @s.aggregate

    if @s.keyword.present?
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
  end
end
