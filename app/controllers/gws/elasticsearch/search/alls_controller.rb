class Gws::Elasticsearch::Search::AllsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Elasticsearch::SearchFilter

  private

  def set_crumbs
    @crumbs << [t('modules.gws/elasticsearch'), gws_elasticsearch_search_all_path]
  end

  def set_search_type
    @search_type = Gws::Board::Post.collection_name
  end
end
