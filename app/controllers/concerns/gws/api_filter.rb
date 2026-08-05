module Gws::ApiFilter
  extend ActiveSupport::Concern
  include Gws::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  private

  def rescue_action(e)
    if e.to_s =~ /^\d+$/
      respond_to do |format|
        format.json { render json: :error, status: e.to_s.to_i }
      end
    else
      raise e
    end
  end

  def set_items
    @items ||= begin
      if @model.respond_to?(:site)
        @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
      else
        @model.allow(:read, @cur_user, site: @cur_site)
      end
    end
  end

  public

  def index
    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end
end
