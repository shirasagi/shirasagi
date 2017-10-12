class Webmail::CacheSettingsController < ApplicationController
  include Webmail::BaseFilter

  menu_view false

  private

  def set_crumbs
    @crumbs << [t("webmail.settings.cache") , { action: :show } ]
    @webmail_other_account_path = :webmail_cache_setting_path
  end

  public

  def show
    # render
  end

  def update
    if params[:model] == 'mail'
      clear_cache_mail
    elsif params[:model] == 'mailbox'
      clear_cache_mailbox
    end
  end

  def clear_cache_mail
    if params[:target] == 'all'
      Webmail::Mail.delete_all
    else
      Webmail::Mail.imap_setting(@imap_setting).delete_all
    end
    render_destroy
  end

  def clear_cache_mailbox
    if params[:target] == 'all'
      Webmail::Mailbox.delete_all
    else
      Webmail::Mailbox.imap_setting(@imap_setting).delete_all
    end
    render_destroy
  end

  def render_destroy
    location = { action: :show }

    respond_to do |format|
      format.html { redirect_to location, notice: t('webmail.notice.deleted_cache') }
      format.json { head :no_content }
    end
  end
end
