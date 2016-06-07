class Member::Apis::PhotosController < ApplicationController
  include Cms::ApiFilter

  model Member::Photo

  layout "ss/ajax"

  def index
    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).per(20)
  end

  def select
    set_item
    render file: :select, layout: !request.xhr?
  end
end
