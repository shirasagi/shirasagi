class Gws::Memo::ImportMessagesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::MessageImporter

  navi_view "gws/memo/messages/navi"
  menu_view nil

  before_action :deny_with_auth

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('gws/memo/message.import_messages'), gws_memo_import_messages_path ]
  end

  def deny_with_auth
    raise "403" unless Gws::Memo::Message.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def import
    if request.get? || request.head?
      return
    end

    @item = @model.new get_params
    return unless @item.save

    Gws::Memo::MessageImportJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later(@item.id)
    render_create true, location: { action: :start_import }, notice: I18n.t("gws/memo/message.notice.start_import")
  end

  def start_import
  end
end
