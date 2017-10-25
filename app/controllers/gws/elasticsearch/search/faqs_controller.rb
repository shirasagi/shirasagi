class Gws::Elasticsearch::Search::FaqsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Elasticsearch::SearchFilter

  def show
    raise '403' unless Gws::Faq::Topic.allowed?(:read, @cur_user, site: @cur_site)
    super
  end

  private

  def set_crumbs
    @crumbs << [t('modules.gws/elasticsearch'), gws_elasticsearch_search_faq_path]
  end

  def set_search_type
    @search_type = Gws::Faq::Post.collection_name
  end
end
