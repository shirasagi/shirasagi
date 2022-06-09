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
    if @webmail_mode == :group
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode)
      return
    end

    @item = @model.new
  end

  def export
    if @webmail_mode == :group
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode)
      return
    end

    @item = @model.new
    if params.dig(:item, :all_export).blank?
      @item.errors.add(:all_export, :blank)
      render action: :index
      return
    end

    unless Webmail::MailExportJob.check_size_limit_per_user?(@cur_user.id)
      @item.errors.add(:base, t('job.notice.size_limit_exceeded'))
      render action: :index
      return
    end

    if params.dig(:item, :all_export).to_s == "select"
      mail_ids = params.dig(:item, :mail_ids)
      mail_ids = mail_ids.select(&:present?) if mail_ids
      if mail_ids.blank?
        @item.errors.add(:mail_ids, :blank)
        render action: :index
        return
      end
    else
      mail_ids = []
    end
    root_url = params.dig(:item, :root_url)

    job_class = Webmail::MailExportJob.bind(user_id: @cur_user, user_password: SS::Crypto.encrypt(@cur_user.decrypted_password))
    job_class.perform_later(mail_ids: mail_ids, root_url: root_url, account: params[:account])
    flash.now[:notice] = I18n.t("webmail.export.start_export")
    redirect_to action: :start_export
  end

  def start_export
  end
end
