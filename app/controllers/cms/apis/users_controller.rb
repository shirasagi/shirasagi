class Cms::Apis::UsersController < ApplicationController
  include Cms::ApiFilter

  model Cms::User

  def index
    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
