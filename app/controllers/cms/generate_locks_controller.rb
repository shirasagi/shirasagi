class Cms::GenerateLocksController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  helper SS::DatetimeHelper

  model Cms::Site

  navi_view "cms/main/conf_navi"

  private

  def fix_params
    { generate_lock_user: @cur_user }
  end

  def set_crumbs
    @crumbs << [t("cms.site_info"), action: :show]
  end

  def set_item
    @item = Cms::Site.find(@cur_site.id)
    @item.attributes = fix_params
  end

  public

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def update
    @item.attributes = get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    @item.generate_lock_until = nil if params[:unlock].present?
    if @item.generate_lock_until.present?
      @notice = I18n.t('cms.notices.generate_locked')
    else
      @notice = I18n.t('cms.notices.generate_unlocked')
    end
    render_update @item.update, notice: @notice
  end
end
