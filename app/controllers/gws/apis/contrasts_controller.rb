class Gws::Apis::ContrastsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Contrast

  def index
    @items = @model.site(@cur_site).and_public.
      search(params[:s]).
      order_by(order: 1)
  end
end
