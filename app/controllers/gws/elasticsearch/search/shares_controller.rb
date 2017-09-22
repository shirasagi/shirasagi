class Gws::Elasticsearch::Search::SharesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Elasticsearch::SearchFilter

  def show
    raise '403' unless Gws::Share::File.allowed?(:read, @cur_user, site: @cur_site)
    super
  end

  private

  def set_crumbs
    @crumbs << [t('modules.gws/elasticsearch'), gws_elasticsearch_search_share_path]
  end

  def set_search_type
    @search_type = 'gws_share_files'
  end
end
