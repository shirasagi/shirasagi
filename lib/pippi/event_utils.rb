class Pippi::EventUtils
  class << self
    def sort_event_page_by_difference(criteria, sort, &block)
      today = Time.zone.today
      case sort
      when "event_dates_today"
        dates = [today]
      when "event_dates_weekend"
        dates = ((today + 1.day)..(today + 6.days)).select do |date|
          date.saturday? || date.sunday?
        end
      else
        return criteria.to_a
      end

      event_sort_hash = {}
      items = criteria.to_a
      items.each do |item|
        event_sort_hash[item.id.to_s] = {}
        cluster = find_cluster(item, dates)
        next unless cluster

        event_sort_hash[item.id.to_s]['difference'] = dates_difference(cluster, dates)
        event_sort_hash[item.id.to_s]['start_date'] = cluster.first
        event_sort_hash[item.id.to_s]['end_date'] = cluster.last
      end
      i = 0
      items.sort_by do |item|
        sort_cond = [
          event_sort_hash[item.id.to_s]['difference'].zero? ? 0 : 1,
          event_sort_hash[item.id.to_s]['start_date'],
          event_sort_hash[item.id.to_s]['end_date'],
          item.released.try(:to_i) * -1,
          i += 1
        ]
        sort_cond = yield(item, sort_cond) if block
        sort_cond
      end
    end

    def find_cluster(item, dates)
      return unless dates
      dates = dates.collect do |date|
        date.try(:to_date) || date
      end
      item.event_dates.clustered.find do |cluster|
        (cluster & dates).present?
      end
    end

    def dates_difference(cluster, dates)
      today = Time.zone.today
      start_date_difference = (today - cluster.first).abs
      end_date_difference = (cluster.last - today).abs
      [start_date_difference, end_date_difference].min
    end
  end
end
