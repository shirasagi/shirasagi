class Gws::Chorg::RevisionsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view 'gws/main/conf_navi'
  model Gws::Chorg::Revision
  append_view_path 'app/views/chorg/revisions'

  private

  def set_crumbs
    @crumbs << [t('modules.gws/chorg'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
