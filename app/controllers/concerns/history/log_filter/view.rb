module History::LogFilter::View
  extend ActiveSupport::Concern

  public
    def delete
      @item = @model.new
    end

  private
    def send_csv(items)
      require "csv"

      csv = CSV.generate do |data|
        data << %w(Date User Target Action URL)
        items.each do |item|
          line = []
          line << item.created.strftime("%Y-%m-%d %H:%m")
          line << item.user_label
          line << item.target_label
          line << item.action
          line << item.url
          data << line
        end
      end

      send_data csv.encode("SJIS"), filename: "history_logs_#{Time.now.to_i}.csv"
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
