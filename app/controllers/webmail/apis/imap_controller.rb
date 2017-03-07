class Webmail::Apis::ImapController < ApplicationController
  include Webmail::BaseFilter
  include SS::AjaxFilter

  before_action :imap_login

  def recent
    @mailboxes = @imap.mailboxes.load
    @mailboxes.apply_recent_filters

    inbox = @mailboxes.inbox
    resp = {}

    if inbox.recent > 0
      resp[:notice] = t('webmail.notice.recent_mail', count: inbox.recent)
    else
      resp[:notice] = t('webmail.notice.no_recent_mail')
    end

    resp[:inbox] = { recent: inbox.recent, unseen: inbox.unseen, url: webmail_mails_path }
    resp[:mailboxes] = @mailboxes.all.map do |box|
      { name: box.original_name, unseen: box.unseen }
    end

    render json: resp.to_json
  end

  def quota
    item = @imap.quota.reload

    resp = {
      label: item.label,
      quota: item.quota,
      usage: item.usage,
      percentage: item.percentage
    }

    render json: resp.to_json
  end
end
