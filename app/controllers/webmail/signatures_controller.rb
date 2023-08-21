class Webmail::SignaturesController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapCrudFilter

  model Webmail::Signature

  before_action :check_group_imap_permissions, if: ->{ @webmail_mode == :group }

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/signature"), { action: :index } ]
    @webmail_other_account_path = :webmail_signatures_path
  end

  def fix_params
    @imap.account_scope.merge(cur_user: @cur_user)
  end

  def check_group_imap_permissions
    unless @cur_user.webmail_permitted_any?(:edit_webmail_group_imap_signatures)
      redirect_to webmail_mails_path(webmail_mode: @webmail_mode, account: params[:account])
    end
  end

  public

  def index
    @items = @model.
      and_imap(@imap).
      search(params[:s]).
      page(params[:page]).
      per(50)
  end
end
