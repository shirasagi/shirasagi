class Webmail::MailboxesController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapFilter
  include Sns::CrudFilter

  model Webmail::Mailbox

  private
    def set_crumbs
      @crumbs << [:'mongoid.models.webmail/mailbox', { action: :index } ]
    end

    def fix_params
      @imap.account_scope.merge(cur_user: @cur_user, sync: true)
    end

    def set_destroy_items
      @items = @model.
        in(id: params[:ids]).
        reorder(depth: -1).
        entries.
        map(&:sync)
    end

    def crud_redirect_url
      { action: :index }
    end

  public
    def index
      @items = @imap.mailboxes.load.without_inbox
    end

    def reload
      @reload_info = @imap.mailboxes.reload_info

      if request.post?
        @imap.mailboxes.reload
        redirect_to url_for(action: :index), notice: t('webmail.notice.reloaded_mailboxes')
      end
    end

    def recent
      mailboxes = @imap.mailboxes.load
      inbox = mailboxes.inbox.status

      resp = {}

      if inbox.recent > 0
        resp[:notice] = t('webmail.notice.recent_mail', count: inbox.recent)
      else
        resp[:notice] = t('webmail.notice.no_recent_mail')
      end

      resp[:inbox] = {
        recent: inbox.recent,
        uidnext: inbox.uidnext,
        unseen: inbox.unseen,
        url: webmail_mails_path
      }
      resp[:mailboxes] = mailboxes.all.map do |box|
        box.status.save
        { name: box.original_name, recent: box.recent, uidnext: box.uidnext, unseen: box.unseen }
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
