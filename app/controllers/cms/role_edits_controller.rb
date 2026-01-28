class Cms::RoleEditsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Group

  navi_view "cms/main/group_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.group"), cms_groups_path]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  def set_item
    @item ||= begin
      item = @model.unscoped.site(@cur_site).find(params[:group_id])
      item.attributes = fix_params
      item
    end
  end

  public

  def edit
    return "404" if @item.users.blank?
    render
  end

  def update
    return "404" if @item.users.blank?

    safe_params = params.require(:item).permit(cms_role_ids: [])
    role_ids = safe_params[:cms_role_ids].select(&:numeric?).map(&:to_i)
    if role_ids.blank?
      render_update true, location: cms_group_path(id: @item)
      return
    end

    @item.users.each do |user|
      set_ids = user.cms_role_ids - Cms::Role.site(@cur_site).map(&:id) + role_ids
      user.set(cms_role_ids: set_ids)
    end
    render_update true, location: cms_group_path(id: @item)
  end
end
