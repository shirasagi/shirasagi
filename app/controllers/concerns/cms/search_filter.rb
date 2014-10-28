module Cms::SearchFilter
  extend ActiveSupport::Concern
  include Cms::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  public
    def index
      search if params[:q]
    end

    def search
      @items = @model.site(@cur_site).
        search(params[:q]).
        order_by(_id: -1)

      render :search, layout: !request.xhr?
    end
end
