class Webmail::SignaturesController < ApplicationController
  include Webmail::BaseFilter
  include Webmail::ImapFilter
  include Sns::CrudFilter

  model Webmail::Signature

  private
    def set_crumbs
      @crumbs << [:'mongoid.models.webmail/signature', { action: :index } ]
    end

    def fix_params
      { cur_user: @cur_user }
    end

  public
    def index
      @items = @model.user(@cur_user).
        page(params[:page]).
        per(50)
    end
end
