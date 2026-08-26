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
    # 運用目的で閲覧可能な項目を選択
    # allow(:read, @cur_user, site: @cur_site) は管理目的で閲覧可能な項目を選択するので使用しない
    @items ||= @model.site(@cur_site).without_deleted
  end

  public

  def index
    set_items

    @items = @items.
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end
end
