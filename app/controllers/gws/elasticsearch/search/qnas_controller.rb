class Gws::Elasticsearch::Search::QnasController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Elasticsearch::SearchFilter

  def show
    raise '403' unless Gws::Qna::Topic.allowed?(:read, @cur_user, site: @cur_site)
    super
  end

  private

  def set_crumbs
    @crumbs << [t('modules.gws/elasticsearch'), gws_elasticsearch_search_qna_path]
  end

  def set_search_type
    @search_type = Gws::Qna::Post.collection_name
  end
end
