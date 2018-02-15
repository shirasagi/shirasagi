class Gws::ContrastsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Contrast

  navi_view 'gws/main/conf_navi'

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.gws/contrast'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
