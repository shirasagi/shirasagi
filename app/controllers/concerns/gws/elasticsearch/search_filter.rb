module Gws::Elasticsearch::SearchFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path 'app/views/gws/elasticsearch/search/main'
    menu_view nil
    model Gws::Elasticsearch::Searcher
    before_action :set_search_type
  end

  private

  def fix_params
    set_search_type
    { cur_site: @cur_site, cur_user: @cur_user, type: @search_type }
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

  def set_search_type
    raise NotImplementedError
  end

  public

  def show
    raise '404' unless @cur_site.elasticsearch_enabled?

    if @s.keyword.present?
      @s.from = (params[:page].to_i - 1) * @s.size if params[:page].present?
      @result = @s.search
    end

    render
  end
end
