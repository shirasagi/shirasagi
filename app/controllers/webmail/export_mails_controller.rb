class Webmail::ExportMailsController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  model Webmail::Mail
  menu_view nil

  private

  def set_crumbs
    @crumbs << [t("webmail.settings.export_mails"), { action: :index } ]
    @webmail_other_account_path = :webmail_export_mails_path
  end

  def fix_params
    { cur_user: @cur_user }
  end

  def permit_fields
  end

  def set_item
    @item = @cur_user
  end

  public

  def index
    @item = @model.new
  end

  def export
    mail_ids = params.dig(:item, :mail_ids)
    mail_ids = mail_ids.select(&:present?) if mail_ids
    root_url = params.dig(:item, :root_url)

    link = Webmail::MailExportJob.bind(site_id: 1, user_id: @cur_user.id).perform_now(mail_ids: mail_ids, root_url: root_url, account: params[:account])
    flash.now[:notice] = I18n.t("webmail.export.start_export")
    redirect_to action: :start_export, link: link
  end

  def start_export
  end
end
