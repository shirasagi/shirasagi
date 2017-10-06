class Webmail::MailboxesController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Mailbox

  before_action :imap_login

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/mailbox"), { action: :index } ]
    @webmail_other_account_path = :webmail_mailboxes_path
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
    return unless request.post?

    @imap.mailboxes.reload
    redirect_to url_for(action: :index), notice: t('webmail.notice.reloaded_mailboxes')
  end
end
