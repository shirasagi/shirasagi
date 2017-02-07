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
      @imap.account_attributes.merge(cur_user: @cur_user, sync: true)
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
      @model.imap_all

      @items = @model.
        page(params[:page]).
        per(50)
    end
end
