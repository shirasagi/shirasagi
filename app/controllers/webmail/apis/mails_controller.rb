class Webmail::Apis::MailsController < ApplicationController
  include Webmail::BaseFilter
  include SS::AjaxFilter

  model Webmail::Mail

  before_action :imap_login
  before_action :set_folders

  private

  def set_folders
    @mailboxes = @imap.mailboxes.load
    @mailboxes.apply_recent_filters
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
end
