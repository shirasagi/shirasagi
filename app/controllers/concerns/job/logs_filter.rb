module Job::LogsFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    model Job::Log
    before_action :filter_permission
    before_action :set_item, only: [:show]
  end

  private
    def set_crumbs
      @crumbs << [:"job.log", action: :index]
    end

    def log_criteria
      @model.site(@cur_site)
    end

    def set_item
      @item = log_criteria.find(params[:id])
      raise "404" unless @item
    end

  public
    def index
      @items = log_criteria.order_by(updated: -1).page(params[:page]).per(50)
    end

    def show
      render
    end

    def download
      @item = @model.new
      # show condition input form if request is get.
      return if request.get?

      from = @model.term_to_date params[:item][:save_term]
      raise "400" if from == false

      cond = {}
      cond[:created] = { "$gte" => from } if from

      @items = log_criteria.where(cond).sort(closed: 1)
      send_csv @items
    end

    def batch_destroy
      @item = @model.new
      # show condition input form if request is get.
      return if request.get?

      begin
        from = @model.term_to_date params[:item][:save_term]
        unless from
          redirect_to({ action: :index }, { notice: t("views.notice.canceled") })
          return
        end

        num = log_criteria.term(from).delete

        compact

        render_destroy num
      rescue
        raise "400"
      end
    end

    def delete_term_options
      @model.delete_term_options
    end
  private
    def send_csv(items)
      csv = build_csv(items)
      send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "job_logs_#{Time.zone.now.to_i}.csv"
    end

    def build_csv(items)
      require "csv"
      CSV.generate do |data|
        data << %w(ClassName Started Closed State Args Logs)
        items.each do |item|
          data << [
            t(item.class_name.underscore, scope: "job.models"),
            item.start_label,
            item.closed_label,
            t(item.state, scope: "job.state"),
            item.args,
            item.joined_jobs
          ]
        end
      end
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

    def compact
      coll = @model.collection
      coll.client.command({ compact: coll.name }) rescue nil
    end
end
