class Gws::Memo::ImportMessagesController < ApplicationController
  include Gws::Memo::ImportAndRestoreFilter

  model Gws::Memo::MessageImporter

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.import_messages'), gws_memo_import_messages_path ]
  end

  public

  def import
    return unless set_item
    @item.import_messages

    render_create true, location: { action: :import }, notice: I18n.t("gws/memo/message.notice.start_import")
  end
end
