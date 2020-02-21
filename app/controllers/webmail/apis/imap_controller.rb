class Webmail::Apis::ImapController < ApplicationController
  include Webmail::BaseFilter
  include SS::AjaxFilter

  before_action :imap_login

  private

  def notice_message(inbox)
    if inbox.recent > 0
      t('webmail.notice.recent_mail', count: inbox.recent)
    else
      t('webmail.notice.no_recent_mail')
    end
  end

  public

  def recent
    @mailboxes = @imap.mailboxes.load
    @mailboxes.apply_recent_filters
    inbox = @mailboxes.inbox

    resp = {
      notice: notice_message(inbox),
      inbox: {
        messages: inbox.messages,
        recent: inbox.recent,
        uidnext: inbox.uidnext,
        unseen: inbox.unseen,
        url: webmail_mails_path(webmail_mode: @webmail_mode || :account, account: params[:account])
      },
      mailboxes: @mailboxes.all.map do |box|
        {
          name: box.name,
          basename: box.basename,
          original_name: box.original_name,
          depth: box.depth,
          messages: box.messages,
          unseen: box.unseen,
          noselect: box.noselect?
        }
      end
    }
    render json: resp.to_json
  end

  def latest
    @mailboxes = @imap.mailboxes.load
    @mailboxes.apply_recent_filters
    inbox = @mailboxes.inbox
    mailbox = params[:mailbox]

    @imap.examine(mailbox)
    @items = @imap.mails.mailbox(mailbox).per(10).all

    resp = {
      notice: notice_message(inbox),
      recent: inbox.recent,
      unseen: inbox.unseen,
      latest: @items.first.try(:internal_date),
      items: @items.map do |item|
        if SS.config.webmail.store_mails
          item = @imap.mails.find_and_store item.uid, :body
        else
          item = @imap.mails.find item.uid, :body
        end
        {
          date: item.internal_date,
          from: item.display_sender.name,
          to: item.display_to.map { |addr| addr.name }.presence,
          cc: item.display_cc.map { |addr| addr.name }.presence,
          subject: item.display_subject,
          text: item.text.presence,
          url: webmail_mail_url(webmail_mode: @webmail_mode || :account, account: params[:account], mailbox: mailbox, id: item.uid),
          unseen: item.unseen?
        }
      end
    }
    render json: resp.to_json
  end

  def quota
    item = @imap.quota.reload
    return render(json: {}) if item.nil?

    resp = {
      label: item.label,
      quota: item.quota,
      usage: item.usage,
      percentage: item.percentage,
      over_threshold: item.over_threshold?,
      threshold_label: item.threshold_label
    }

    render json: resp.to_json
  end
end
