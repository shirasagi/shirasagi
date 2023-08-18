class Gws::Elasticsearch::Diagnostic::StatisticsController < ApplicationController
  include Gws::BaseFilter

  navi_view "gws/elasticsearch/diagnostic/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [ "Elasticsearch", gws_elasticsearch_diagnostic_main_path ]
    @crumbs << [ "Stats", url_for(action: :show) ]
  end

  public

  def show
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_groups)
    if @cur_site.elasticsearch_client.nil?
      head :not_found
      return
    end

    render
  end
end
