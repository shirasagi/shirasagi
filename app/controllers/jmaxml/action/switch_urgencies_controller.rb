class Jmaxml::Action::SwitchUrgenciesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Jmaxml::Action::SwitchUrgency
  navi_view "rss/main/navi"
  append_view_path 'app/views/jmaxml/action/bases'

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def index
      redirect_to jmaxml_action_bases_path
    end
end
