class Contact::UnifiesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model SS::Group

  navi_view "cms/main/group_navi"

  private

  def set_crumbs
    set_item
    @crumbs << [ t("cms.group"), cms_groups_path ]
    @crumbs << [ @item.name, cms_group_path(id: @item.id) ]
  end

  def set_item
    @item ||= Cms::Group.find(params[:group_id])
  end
end
