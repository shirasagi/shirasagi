module Gws::ApiFilter
  extend ActiveSupport::Concern
  include Gws::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  def index
    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end
end
