module Inquiry::Addon

  module Aggregation
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 490

    included do
      field :aggregation_state, type: String, default: "disabled"
      permit_params :aggregation_state

      public
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

        def aggregate_select_columns
          selects = columns.select { |c| c.input_type =~ /(select|radio_button|check_box)/ }
          pipes = []
          pipes << { "$unwind"=>"$data" }
          pipes << { "$unwind"=>"$data.values" }
          pipes << { "$match" => { "data.column_id" => { "$in" => selects.map(&:id) } } }
          pipes << { "$group" => {
            _id: { "column_id" => "$data.column_id", "value" => "$data.values" },
            count: { "$sum"=> 1 }
          } }
          aggregation = Inquiry::Answer.collection.aggregate(pipes)
          aggregation = aggregation.map { |i| [ i["_id"], i["count"] ] }.to_h
          aggregation.default = 0
          aggregation
        end
    end
  end

end
