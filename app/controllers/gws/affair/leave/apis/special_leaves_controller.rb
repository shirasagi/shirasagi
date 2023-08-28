class Gws::Affair::Leave::Apis::SpecialLeavesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::SpecialLeave

  def index
    @user = Gws::User.active.find_by(id: params[:uid])

    @items = @model.site(@cur_site).
      where(staff_category: @user.staff_category).
      search(params[:s]).
      order_by(order: 1).
      page(params[:page]).per(50)
  end
end
