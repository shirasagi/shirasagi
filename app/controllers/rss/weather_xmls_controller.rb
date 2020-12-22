class Rss::WeatherXmlsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Rss::WeatherXmlPage
  navi_view "rss/main/navi"
  before_action :convert_cur_node

  private

  def append_view_paths
    super
    append_view_path "app/views/cms/pages"
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def convert_cur_node
    save = @cur_node
    @cur_node = @cur_node.becomes_with_route rescue save if @cur_node.present?
  end
end
