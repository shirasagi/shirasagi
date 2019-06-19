class Webmail::CacheSettingsController < ApplicationController
  include Webmail::BaseFilter

  menu_view false

  before_action :check_group_imap_permissions, if: ->{ @webmail_mode == :group }

  private

  def set_crumbs
    @crumbs << [t("webmail.settings.cache"), { action: :show } ]
    @webmail_other_account_path = :webmail_cache_setting_path
  end

  def check_group_imap_permissions
    unless @cur_user.webmail_permitted_any?(:edit_webmail_group_imap_caches)
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode, account: params[:account])
    end
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
      items = Webmail::Mail.all
    else
      items = Webmail::Mail.and_imap(@imap)
    end
    items.each(&:destroy_rfc822)
    items.delete_all
    render_destroy
  end

  def clear_cache_mailbox
    if params[:target] == 'all'
      Webmail::Mailbox.delete_all
    else
      Webmail::Mailbox.and_imap(@imap).delete_all
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
