class Webmail::SignaturesController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapCrudFilter

  model Webmail::Signature

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/signature"), { action: :index } ]
    @webmail_other_account_path = :webmail_signatures_path
  end

  def fix_params
    @imap.account_scope.merge(cur_user: @cur_user)
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
