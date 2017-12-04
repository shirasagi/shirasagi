class Gws::Circular::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Category

  private

  def set_crumbs
    @crumbs << [t('gws/circular.setting'), gws_circular_setting_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end

