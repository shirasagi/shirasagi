class Gws::Memo::RestoreMessagesController < ApplicationController
  include Gws::Memo::ImportAndRestoreFilter

  model Gws::Memo::MessageRestorer

  before_action :check_permission

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.restore_messages'), gws_memo_restore_messages_path ]
  end

  def check_permission
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :restore_gws_memo_messages)
  end

  public

  def restore
    return unless set_item
    @item.restore_messages

    render_create true, location: { action: :restore }, notice: I18n.t("gws/memo/message.notice.start_restore")
  end
end
