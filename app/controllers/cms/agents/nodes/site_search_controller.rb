class Cms::Agents::Nodes::SiteSearchController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  before_action :set_setting

  model Cms::Elasticsearch::Searcher

  private

  def set_setting
    @setting ||= begin
      setting_model = Cms::Elasticsearch::Setting::Page
      setting_model.new(cur_site: @cur_site, cur_user: @cur_user)
    end
  end

  def fix_params
    { setting: @setting }
  end

  def permit_fields
    [:keyword]
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

    if @s.keyword.present?
      @s.from = (params[:page].to_i - 1) * @s.size if params[:page].present?
      @result = @s.search
    end
  end
end
