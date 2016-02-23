module Cms::SearchableCrudFilter
  extend ActiveSupport::Concern

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:edit, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(name: 1).
      page(params[:page]).per(50)
  end
end
