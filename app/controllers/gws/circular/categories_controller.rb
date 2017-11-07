class Gws::Circular::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Category

  private

  def set_crumbs
    @crumbs << [t('modules.gws/circular'), gws_circular_posts_path]
    @crumbs << [t('gws/circular.admin'), gws_circular_categories_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end

