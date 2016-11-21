class Jmaxml::Trigger::LandslideInfosController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Jmaxml::Trigger::LandslideInfo
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      redirect_to jmaxml_trigger_bases_path
    end
end
