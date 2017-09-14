class Gws::Elasticsearch::Search::AllsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Elasticsearch::SearchFilter

  def show
    set_search_type
    raise '403' if @search_type.blank?
    super
  end

  private

  def set_crumbs
    @crumbs << [t('modules.gws/elasticsearch'), gws_elasticsearch_search_all_path]
  end

  def set_search_type
    @search_type ||= begin
      search_type = []
      search_type << Gws::Board::Post.collection_name if Gws::Board::Topic.allowed?(:read, @cur_user, site: @cur_site)
      search_type << 'gws_share_files' if Gws::Share::File.allowed?(:read, @cur_user, site: @cur_site)
      search_type
    end
  end
end
