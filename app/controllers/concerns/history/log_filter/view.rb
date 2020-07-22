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
    user_ids = params.dig(:item, :user_ids)
    user_ids.reject!(&:blank?) if user_ids.present?
    raise "500" if from == false

    @items = @model.where(cond)
    @items = @items.in(user: user_ids) if user_ids.present?
    @items = @items.where(created: { "$gte" => from }) if from
    @items = @items.sort(created: 1, id: 1)
    send_csv @items
  end

  private

  def send_csv(items)
    require "csv"

    csv = CSV.generate do |data|
      header = %w(created user_name model_name action path session_id request_id)
      data << header.collect { |k| History::Log.t(k) }
      items.each do |item|
        line = []
        line << item.created.strftime("%Y-%m-%d %H:%M")
        line << item.user_label
        line << item.target_label
        line << item.action
        line << item.url
        line << item.session_id
        line << item.request_id
        data << line
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "history_logs_#{Time.zone.now.to_i}.csv"
  end

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
