module Gws::Elasticsearch::SearchFilter
  extend ActiveSupport::Concern

  included do
    append_view_path 'app/views/gws/elasticsearch/search/main'
    menu_view nil
    model Gws::Elasticsearch::Searcher
    before_action :set_type
    before_action :set_setting
    before_action :set_item
  end

  private

  def set_type
    @cur_type ||= begin
      type = params[:type]
      type.singularize
    end

    raise '404' if !Gws::Elasticsearch::Searcher::WELL_KNOWN_TYPES.include?(@cur_type)
  rescue
    raise '404'
  end

  def set_crumbs
    set_type
    @crumbs << [@cur_site.menu_elasticsearch_label || t('modules.gws/elasticsearch'), gws_elasticsearch_search_main_path]
    @crumbs << [t("gws/elasticsearch.tabs.#{@cur_type}"), gws_elasticsearch_search_search_path]
  end

  def set_setting
    @setting ||= begin
      setting_model = "Gws::Elasticsearch::Setting::#{@cur_type.classify}".constantize
      setting_model.new(cur_site: @cur_site, cur_user: @cur_user)
    end
  end

  def fix_params
    { setting: @setting }
  end

  def get_params
    if params[:s].present?
      params.require(:s).permit(permit_fields).merge(fix_params)
    else
      fix_params
    end
  end

  def set_item
    @s = @item = @model.new(get_params)
  end

  public

  def show
    raise '404' unless @cur_site.elasticsearch_enabled?
    raise '403' if @setting.search_types.blank?

    prepend_view_path "app/views/gws/elasticsearch/search/#{@cur_type}"

    if @s.keyword.present?
      @s.from = (params[:page].to_i - 1) * @s.size if params[:page].present?
      @result = @s.search
    end

    render
  end
end
