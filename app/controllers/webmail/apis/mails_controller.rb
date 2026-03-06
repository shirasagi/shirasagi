class Webmail::Apis::MailsController < ApplicationController
  include Webmail::BaseFilter
  include SS::AjaxFilter

  model Webmail::Mail

  before_action :imap_login, except: :imap_error
  before_action :set_folders, except: :imap_error

  private

  def imap_initialize
    super

    @redirect_path = webmail_apis_mails_imap_error_path
  end

  def set_folders
    @mailboxes = @imap.mailboxes.load
    @mailboxes.apply_recent_filters
  end

  def skip_update_last_logged_in?
    params[:action] == "auto_save"
  end

  public

  def index
    s_params = params[:s] || {}

    mailbox = s_params[:mailbox] || 'INBOX'
    @imap.select(mailbox)

    if s_params[:mailbox].present?
      @cur_mailbox = @mailboxes.all.select { |mailbox| mailbox.original_name == s_params[:mailbox] }.first
    end
    @cur_mailbox ||= @mailboxes.all.first

    @items = @imap.mails.
      mailbox(mailbox).
      search(s_params).
      page(params[:page]).
      per(50).
      all
  end

  def imap_error
  end

  def auto_save
    @model = Webmail::AutoSave
    @auto_save = @model.user(@cur_user).find(params[:auto_save_id]) rescue nil
    raise "404" if @auto_save.nil?

    permit_fields = @model.permitted_fields
    fix_params = { cur_user: @cur_user }
    get_params = params.require(:item).permit(permit_fields).merge(fix_params)

    @auto_save.attributes = get_params
    @auto_save.update!
    @auto_save.ready!
    head :ok
  end
end
