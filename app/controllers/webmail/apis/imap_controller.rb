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
        recent: inbox.recent,
        unseen: inbox.unseen,
        url: webmail_mails_path
      },
      mailboxes: @mailboxes.all.map do |box|
        {
          name: box.original_name,
          unseen: box.unseen
        }
      end
    }
    render json: resp.to_json
  end

  def latest
    @mailboxes = @imap.mailboxes.load
    inbox = @mailboxes.inbox.status

    @imap.examine('INBOX')
    @items = @imap.mails.mailbox('INBOX').per(10).all

    resp = {
      notice: notice_message(inbox),
      recent: inbox.recent,
      unseen: inbox.unseen,
      latest: @items.first.try(:internal_date),
      items: @items.map do |item|
        {
          date: item.internal_date,
          from: item.display_sender.name,
          subject: item.display_subject,
          url: webmail_mail_url(mailbox: 'INBOX', id: item.uid)
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
