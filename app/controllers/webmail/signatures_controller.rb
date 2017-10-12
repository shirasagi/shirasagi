class Webmail::SignaturesController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model Webmail::Signature

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/signature"), { action: :index } ]
    @webmail_other_account_path = :webmail_signatures_path
  end

  def fix_params
    { cur_user: @cur_user }
  end

  public

  def index
    @items = @model.
      user(@cur_user).
      search(params[:s]).
      page(params[:page]).
      per(50)
  end
end
