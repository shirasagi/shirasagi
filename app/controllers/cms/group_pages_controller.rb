class Cms::GroupPagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Group

  navi_view "cms/main/conf_navi"

  helper_method :group_item, :contact_item

  private

  def set_crumbs
    @crumbs << [ t("cms.group"), cms_groups_path ]
    @crumbs << [ group_item.name, cms_group_path(id: group_item.id) ]
  end

  def group_item
    @group_item ||= Cms::Group.all.allow(:read, @cur_user, site: @cur_site).find(params[:group_id])
  end

  def contact_item
    @contact_item ||= begin
      contact = group_item.contact_groups.where(id: params[:contact_id]).first
      if contact.blank?
        head :not_found
        return
      end
      contact
    end
  end

  def items
    @items ||= begin
      criteria = Cms::Page.all.site(@cur_site)
      criteria = criteria.where(contact_group_id: group_item.id, contact_group_contact_id: contact_item.id)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria
    end
  end

  public

  def index
    items
    render
  end
end
