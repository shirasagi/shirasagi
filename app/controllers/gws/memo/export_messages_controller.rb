class Gws::Memo::ExportMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Message

  navi_view "gws/memo/messages/navi"
  menu_view nil

  before_action :deny_with_auth

  private

  def deny_with_auth
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.export_messages'), gws_memo_export_messages_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @item = @model.new
  end

  def export
    message_ids = params.dig(:item, :message_ids)
    message_ids = message_ids.select(&:present?) if message_ids
    root_url = params.dig(:item, :root_url)

    if message_ids.blank?
      @item = @model.new
      @item.errors.add :base, I18n.t("gws/memo/message.errors.blank_message")
      render file: :index
      return
    end

    Gws::Memo::MessageExportJob.bind(site_id: @cur_site.id, user_id: @cur_user).perform_now(message_ids: message_ids, root_url: root_url)
    render_create true, location: { action: :start_export }, notice: I18n.t("gws/memo/message.notice.start_export")
  end

  def start_export
    #
  end
end
