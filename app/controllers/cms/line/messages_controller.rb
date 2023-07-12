class Cms::Line::MessagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::Message

  navi_view "cms/line/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.line_message"), cms_line_messages_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_items
    super
    @items = @items.order_by(updated: -1)
  end

  public

  def copy
    set_item
    if request.get? || request.head?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}" unless @item.cloned_name?
      return
    end

    @copy = @item.copy_and_save(name: get_params["name"])
    render_update @copy.errors.empty?, location: { action: :index }, render: { action: :copy }
  end

  def deliver
    set_item
    return if request.get? || request.head?

    if @item.deliver
      redirect_to({ action: :show }, { notice: I18n.t("ss.notice.started_deliver") })
    end
  end

  def test_deliver
    set_item

    @test_members = Cms::Line::TestMember.site(@cur_site).allow(:read, @cur_user, site: @cur_site)

    if request.get? || request.head?
      @checked_ids = @test_members.and_default_checked.pluck(:id)
    else
      @checked_ids = params.dig(:item, :test_member_ids).to_a.map(&:to_i) rescue []
      @deliver_members = @test_members.in(id: @checked_ids).to_a

      if @deliver_members.blank?
        @item.errors.add :base, I18n.t("errors.messages.not_found_test_members")
        return
      end
      if @item.test_deliver(@deliver_members)
        redirect_to({ action: :show }, { notice: I18n.t("ss.notice.started_test_deliver") })
      end
    end
  end
end
