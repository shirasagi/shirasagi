module History::LogFilter::View
  extend ActiveSupport::Concern

  def index
    @items = @model.where(cond).
      order_by(created: -1, id: -1).
      page(params[:page]).per(50)
  end

  def delete
    @item = @model.new
  end

  def destroy
    from = @model.term_to_date params[:item][:save_term]
    raise "500" if from == false

    num  = @model.where(cond).where(created: { "$lt" => from }).destroy_all

    coll = @model.collection
    coll.client.command({ compact: coll.name })

    render_destroy num
  end

  def download
    @item = @model.new
    return if request.get?

    from = @model.term_to_date params[:item][:save_term]
    raise "500" if from == false

    @items = @model.where(cond)
    @items = @items.where(created: { "$gte" => from }) if from
    @items = @items.sort(created: 1, id: 1)
    send_csv @items
  end

  private
    def send_csv(items)
      require "csv"

      csv = CSV.generate do |data|
        data << %w(Date User Target Action URL)
        items.each do |item|
          line = []
          line << item.created.strftime("%Y-%m-%d %H:%M")
          line << item.user_label
          line << item.target_label
          line << item.action
          line << item.url
          data << line
        end
      end

      send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "history_logs_#{Time.zone.now.to_i}.csv"
    end

    def render_destroy(result, opts = {})
      location = opts[:location].presence || { action: :index }

      if result
        respond_to do |format|
          format.html { redirect_to location, notice: t("views.notice.deleted") }
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
