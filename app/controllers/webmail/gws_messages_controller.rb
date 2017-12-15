require "net/imap"
class Webmail::GwsMessagesController < ApplicationController
  include Webmail::BaseFilter
  include Gws::BaseFilter
  include Sns::CrudFilter
  helper Webmail::MailHelper

  model Webmail::GwsMessage

  skip_before_action :set_selected_items
  before_action :imap_login
  before_action :set_mailbox
  before_action :set_mail

  private

  def set_crumbs
    @crumbs << [t("webmail.mail"), webmail_mails_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_mailbox
    @navi_mailboxes = true
    @mailbox = params[:mailbox]

    if params[:action] == 'index' || params[:action] =~ /^(set_|unset_)/
      @imap.select(@mailbox)
    else
      @imap.examine(@mailbox)
    end
  end

  def set_mail
    if SS.config.webmail.store_mails
      @mail = @imap.mails.find_and_store params[:id], :body
    else
      @mail = @imap.mails.find params[:id], :body
    end
    @mail.attributes = @imap.account_scope.merge(cur_user: @cur_user, mailbox: @mailbox, imap: @imap)
  end

  public

  def new
    @item = @model.new fix_params
    @item.subject = @mail.subject
    @item.text = @mail.text
    @item.html = @mail.html
    @item.format = @mail.format
    @item.set_ref_files(@mail.attachments)
    @item.imap = @imap
  end

  def create
    @item = @model.new get_params
    @item.imap = @imap
    @item.set_ref_files(@mail.attachments)
    @item.send_date = Time.zone.now
    render_create @item.save, location: gws_memo_messages_path(folder: 'INBOX')
  end
end
