class Gws::Affair::Leave::Apis::SpecialLeavesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::SpecialLeave

  def index
    s = params[:s].presence || {}
    s[:staff_category] ||= @cur_user.staff_category

    @items = @model.site(@cur_site).
      search(s).
      order_by(order: 1).
      page(params[:page]).per(50)
  end
end
