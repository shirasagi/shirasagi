module Event::Addon
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def sort_options
      [
        [I18n.t('event.options.sort.name'), 'name'],
        [I18n.t('event.options.sort.filename'), 'filename'],
        [I18n.t('event.options.sort.created'), 'created'],
        [I18n.t('event.options.sort.updated_1'), 'updated -1'],
        [I18n.t('event.options.sort.released_1'), 'released -1'],
        [I18n.t('event.options.sort.order'), 'order'],
        [I18n.t('event.options.sort.event_dates'), 'event_dates'],
        [I18n.t('event.options.sort.unfinished_event_dates'), 'unfinished_event_dates'],
      ]
    end

    def condition_hash(opts = {})
      cond = super
      if sort == "event_dates"
        cond["event_dates.0"] = { "$exists" => true }
      elsif sort == "unfinished_event_dates"
        cond["event_dates"] = { "$elemMatch" => { "$gte" => Time.zone.today } }
      end
      cond
    end

    def sort_hash
      return { released: -1 } if sort.blank?

      if sort =~ /event_dates/
        { "event_dates.0" => 1 }
      else
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
    end
  end
end
