class Ezine::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Ezine::Page

  append_view_path "app/views/cms/pages"
  navi_view "ezine/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def pre_params
    super.merge(state: 'closed')
  end

  def load_pages
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).node(@cur_node).
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).per(50)
  end

  def load_members(model)
    @members = model.where(node_id: @cur_node.id).enabled.order_by(updated: -1)
    @members_email = @members.reduce("") { |a, e| a += e.email + "\n" }
  end

  public

  def index
    load_pages
  end

  def delivery_confirmation
    @crumbs << [t("ezine.deliver"), action: :delivery_confirmation]

    set_item
    load_members Ezine::Member
  end

  def delivery
    @crumbs << [t("ezine.deliver"), action: :delivery_confirmation]

    page = Ezine::Page.find(params[:id])
    Ezine::DeliverJob.bind(site_id: @cur_site, node_id: @cur_node, page_id: page).perform_later
    redirect_to({ action: :delivery_confirmation }, { notice: t("ezine.notice.delivered") })
  end

  def delivery_test_confirmation
    @crumbs << [t("ezine.deliver_test"), action: :delivery_test_confirmation]

    set_item
    load_members Ezine::TestMember
  end

  def delivery_test
    @crumbs << [t("ezine.deliver_test"), action: :delivery_test_confirmation]

    page = Ezine::Page.find(params[:id])
    page.deliver_to_test_members
    redirect_to({ action: :delivery_test_confirmation }, { notice: t("ezine.notice.delivered_test") })
  end

  def sent_logs
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

    @crumbs << [t("ezine.sent_log"), action: :sent_logs]

    set_item
    @items = Ezine::SentLog.where(node_id: params[:cid], page_id: params[:id]).
      order_by(created: -1).
      page(params[:page]).per(50)
  end
end
