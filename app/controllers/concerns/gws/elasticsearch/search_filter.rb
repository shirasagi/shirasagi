module Gws::Elasticsearch::SearchFilter
  extend ActiveSupport::Concern

  included do
    prepend_view_path 'app/views/gws/elasticsearch/search/main'
    menu_view nil
    model nil
    before_action :set_search_type
    before_action :set_search_params
  end

  private

  def set_item
  end

  def set_crumbs
  end

  def fix_params
  end

  def set_search_type
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
  end

  public

  def show
    raise '404' unless @cur_site.elasticsearch_enabled?

    if @s.keyword.present?
      @result = Gws::Elasticsearch::Searcher.search(@cur_site, @cur_user, @search_type, @s.keyword)
    end

    render
  end
end
