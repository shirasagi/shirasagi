class Jmaxml::Trigger::TsunamiAlertsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Jmaxml::Trigger::TsunamiAlert
  navi_view "rss/main/navi"
  append_view_path 'app/views/jmaxml/trigger/bases'

  private
  def fix_params
    { cur_site: @cur_site }
  end

  public
  def index
    redirect_to jmaxml_trigger_bases_path
  end
end
