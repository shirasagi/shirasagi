class Gws::Affair::Overtime::Apis::CapitalsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::Capital

  def index
    @items = @model.site(@cur_site).
      and_date(@cur_site, Time.zone.today).
      search(params[:s]).
      order_by(order: 1).
      page(params[:page]).per(50)
  end

  def effective
    @user = Gws::User.site(@cur_site).find(params[:uid])
    @capital = @user.effective_capital(@cur_site) if @user
    render layout: false
  end
end
