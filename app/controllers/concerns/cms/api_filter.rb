module Cms::ApiFilter
  extend ActiveSupport::Concern
  include Cms::BaseFilter
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
    @items ||= @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site)
  end

  public

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end
end
