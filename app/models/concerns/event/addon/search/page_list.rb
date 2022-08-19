module Event::Addon::Search
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def sort_options
      %w(
        name filename created updated_desc released_desc order order_desc event_dates
      ).map do |k|
        description = I18n.t("event.sort_options.#{k}.description", default: [ "cms.sort_options.#{k}.description".to_sym, nil ])

        [
          I18n.t("event.sort_options.#{k}.title".to_sym, default: "cms.sort_options.#{k}.title".to_sym),
          k.sub("_desc", " -1"),
          "data-description" => description
        ]
      end
    end

    def condition_hash(opts = {})
      h = super
      case sort
      when "event_dates"
        { "$and" => [ h, { "event_dates.0" => { "$exists" => true } } ] }
      else h
      end
    end

    def sort_hash
      return { released: -1 } if sort.blank?

      if sort.match?(/event_dates/)
        event_dates_sort_hash
      else
        { sort.sub(/ .*/, "") => (/-1$/.match?(sort) ? -1 : 1) }
      end
    end

    def event_dates_sort_hash
      { "event_dates.0" => 1 }
    end
  end
end
