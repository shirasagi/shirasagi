class Cms::GroupPagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Group

  navi_view "cms/main/conf_navi"

  helper_method :group_item, :contact_item, :find_node

  private

  def set_crumbs
    @crumbs << [ t("cms.group"), cms_groups_path ]
    @crumbs << [ group_item.name, cms_group_path(id: group_item.id) ]
  end

  def group_item
    @group_item ||= Cms::Group.all.allow(:read, @cur_user, site: @cur_site).find(params[:group_id])
  end

  def contact_item
    return @contact_item if instance_variable_defined?(:@contact_item)

    contact = group_item.contact_groups.where(id: params[:contact_id]).first
    if contact.blank?
      head :not_found
      return
    end
    @contact_item = contact
  end

  def all_items
    @all_items ||= begin
      criteria = Cms::Page.all.site(@cur_site)
      criteria = criteria.where(contact_group_id: group_item.id, contact_group_contact_id: contact_item.id)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria
    end
  end

  def find_node(filename)
    @all_nodes ||= begin
      all_filenames = all_items.pluck(:filename)
      all_node_filenames = all_filenames.map { |filename| ::File.dirname(filename) }
      all_node_filenames.uniq!
      criteria = Cms::Node.site(@cur_site)
      criteria = criteria.in(filename: all_node_filenames)
      criteria.index_by(&:filename)
    end
    @all_nodes[filename]
  end

  public

  def index
    @items = all_items.criteria.reorder(depth: 1, filename: 1, updated: -1).page(params[:page]).per(50)

    render
  end
end
