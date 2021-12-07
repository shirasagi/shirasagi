require "net/imap"
class Webmail::GwsMessagesController < ApplicationController
  include Webmail::BaseFilter
  include Gws::BaseFilter
  include Sns::CrudFilter
  helper Webmail::MailHelper

  model Gws::Memo::Message

  skip_before_action :set_selected_items
  before_action :imap_login
  before_action :set_mailbox
  before_action :set_mail

  private

  def set_crumbs
    @crumbs << [t("webmail.mail"), webmail_mails_path(webmail_mode: @webmail_mode) ]
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
    @item.subject = @mail.display_subject
    @item.text = @mail.text
    @item.html = @mail.html
    @item.format = @mail.format

    ref_files = @mail.attachments.map do |part|
      Webmail::PartFile.new(
        webmail_mode: @webmail_mode, account: params[:account] || @cur_user.imap_default_index,
        mail: @mail, part: part
      )
    end
    @item.singleton_class.send(:define_method, :ref_files) do
      ref_files
    end

    @dedicated = true
    render layout: "ss/dedicated"
  end

  def create
    @item = @model.new get_params
    @item.in_validate_presence_member = true

    ref_files = @mail.attachments.
      select { |part| @item.ref_file_ids.present? && @item.ref_file_ids.include?("ref-#{part.section}") }.
      map do |part|
        Webmail::PartFile.new(
          webmail_mode: @webmail_mode, account: params[:account] || @cur_user.imap_default_index,
          mail: @mail, part: part
        )
      end
    @item.singleton_class.send(:define_method, :ref_files) do
      ref_files
    end

    render_opts = {
      notice: t('ss.notice.sent'),
      location: sent_webmail_mails_path(webmail_mode: @webmail_mode, account: params[:account] || @cur_user.imap_default_index),
      render: { template: "new", layout: "ss/dedicated" }
    }

    @dedicated = true
    render_create @item.save, render_opts
  end
end
