class Contact::UnifiesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Group

  navi_view "cms/main/group_navi"

  skip_before_action :set_item
  helper_method :group_item, :main_contact, :sub_contacts

  private

  def set_crumbs
    @crumbs << [ t("cms.group"), cms_groups_path ]
    @crumbs << [ group_item.name, cms_group_path(id: group_item.id) ]
  end

  def group_item
    @group_item ||= Cms::Group.find(params[:group_id])
  end

  def main_contact
    return @main_contact if instance_variable_defined?(:@main_contact)
    @main_contact = group_item.contact_groups.where(main_state: "main").first
  end

  def sub_contacts
    return @sub_contacts if instance_variable_defined?(:@sub_contacts)

    if main_contact
      @sub_contacts = group_item.contact_groups.ne(id: main_contact.id).to_a
    else
      @sub_contacts = group_item.contact_groups.to_a
    end
  end

  public

  def show
    raise "403" unless group_item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    @item = Contact::UnifyParam.new(
      main_id: main_contact.try(:id), sub_ids: sub_contacts.map(&:id).map(&:to_s)
    )
    if @item.invalid?
      redirect_to cms_group_path(id: group_item.id), notice: @item.errors.full_messages.join("\n")
      return
    end

    render
  end

  def update
    raise "403" unless group_item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    @item = Contact::UnifyParam.new
    @item.attributes = params.require(:item).permit(:main_id, sub_ids: [])
    if @item.invalid?
      render_update false, location: cms_group_path(id: group_item.id), render: { template: "show" }
      return
    end

    job_class = Contact::UnifyJob.bind(site_id: @cur_site, user_id: @cur_user)
    job_class.perform_now(group_item.id, @item.main_id, @item.sub_ids)
    render_opts = {
      location: cms_group_path(id: group_item.id),
      render: { template: "show" },
      notice: t("contact.notices.unified")
    }
    render_update true, render_opts
  end
end
