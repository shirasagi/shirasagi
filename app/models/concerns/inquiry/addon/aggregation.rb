module Inquiry::Addon
  module Aggregation
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :aggregation_state, type: String, default: "disabled"
      permit_params :aggregation_state
    end

    def aggregation_state_options
      [
        [I18n.t('inquiry.options.state.disabled'), 'disabled'],
        [I18n.t('inquiry.options.state.enabled'), 'enabled'],
      ]
    end

    def aggregation_enabled?
      if reception_close_date.present? && Time.zone.now.to_date <= reception_close_date.to_date
        false
      else
        aggregation_state == "enabled"
      end
    end

    def aggregate_select_columns(params = {})
      pipes = []
      pipes << { "$unwind"=>"$data" }
      pipes << { "$unwind"=>"$data.values" }

      match = build_match_stage(params)

      selects = columns.select { |c| c.input_type =~ /(select|radio_button|check_box)/ }
      match["data.column_id"] = { "$in" => selects.map(&:id) }

      pipes << { "$match" => match } if match.present?

      pipes << { "$group" => {
        _id: { "column_id" => "$data.column_id", "value" => "$data.values" },
        count: { "$sum"=> 1 }
      } }
      aggregation = Inquiry::Answer.collection.aggregate(pipes)
      aggregation = aggregation.map { |i| [ i["_id"], i["count"] ] }.to_h
      aggregation.default = 0

      count = {}
      count.default = 0
      aggregation.each { |k, v| count[{ "column_id" => k["column_id"] }] += v }
      aggregation.merge(count)
    end

    def aggregate_for_list(params = {})
      pipes = []

      match = build_match_stage(params)
      pipes << { "$match" => match } if match.present?

      pipes << { "$group" => {
        "_id" => "$source_url",
        "source_name" => { "$max" => "$source_name" },
        "count" => { "$sum" => 1 },
        "updated" => { "$max" => "$updated" } } }
      pipes << { "$sort" => { "updated" => -1 } }

      Inquiry::Answer.collection.aggregate(pipes)
    end

    private
      def build_match_stage(params = {})
        match = {}

        match["site_id"] = params[:site].id if params[:site].present?

        match["node_id"] = params[:node].id if params[:node].present?

        match["source_url"] = /^#{Regexp.escape(params[:url])}/ if params[:url].present?
        match["source_url"] ||= { "$exists" => true, "$ne" => nil } if params[:feedback]

        if params[:year].present?
          year = params[:year].to_i
          if params[:month].present?
            month = params[:month].to_i
            sdate = Date.new year, month, 1
            edate = sdate + 1.month
          else
            sdate = Date.new year, 1, 1
            edate = sdate + 1.year
          end

          match["updated"] = { "$gte" => sdate, "$lt" => edate }
        end

        match
      end
  end
end
