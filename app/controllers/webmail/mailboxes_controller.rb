class Webmail::MailboxesController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Mailbox

  before_action :imap_login
  before_action :check_group_imap_permissions, if: ->{ @webmail_mode == :group }

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/mailbox"), { action: :index } ]
    @webmail_other_account_path = :webmail_mailboxes_path
  end

  def fix_params
    @imap.account_scope.merge(cur_user: @cur_user, imap: @imap, sync: true)
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

  def check_group_imap_permissions
    unless @cur_user.webmail_permitted_any?(:edit_webmail_group_imap_mailboxes)
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode, account: params[:account])
    end
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

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user)
        item.attributes = fix_params
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
