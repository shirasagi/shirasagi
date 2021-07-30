module History::LogFilter::View
  extend ActiveSupport::Concern

  def index
    @ref_coll_options = [Cms::Node, Cms::Page, Cms::Part, Cms::Layout, SS::File].collect do |model|
      [model.model_name.human, model.collection_name]
    end
    @ref_coll_options.unshift([I18n.t('ss.all'), 'all'])
    @s = OpenStruct.new params[:s]
    @s[:ref_coll] ||= 'all'
    @items = @model.where(cond).search(@s)
               .order_by(created: -1)
               .page(params[:page])
               .per(50)
  end

  def delete
    @item = History::DeleteParam.new
  end

  def destroy
    item = History::DeleteParam.new params.require(:item).permit(:delete_term)
    if item.invalid?
      render
      return
    end

    num = @model.where(cond).lt(created: item.delete_term_in_time).destroy_all

    coll = @model.collection
    coll.client.command({ compact: coll.name })

    render_destroy num
  end

  def download
    @item = History::DownloadParam.new
    return if request.get?

    @item.attributes = params.require(:item).permit(:encoding, :save_term, user_ids: [])
    if @item.invalid?
      render
      return
    end

    items = @model.where(cond)
    items = items.in(user: @item.user_ids) if @item.user_ids.present? && @item.user_ids.any?(&:present?)
    @item.save_term_in_time.try do |from|
      items = items.gte(created: from)
    end
    items = items.reorder(created: 1)

    enumerable = items.enum_csv(cur_site: @cur_site, encoding: @item.encoding)
    filename = "history_logs_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  private

  def render_destroy(result, opts = {})
    location = opts[:location].presence || { action: :index }

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: t("ss.notice.deleted") }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render file: :delete }
        format.json { render json: :error, status: :unprocessable_entity }
      end
    end
  end
end
