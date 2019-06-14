class Gws::Schedule::TodoLimit
  Base = Struct.new(:id, :name)

  class OutDated < Base
    def initialize(threshold)
      super("out_dated", I18n.t("gws/schedule/todo.header.out_dated"))
      @threshold = threshold
    end

    def collect(items)
      items.select { |item| item.end_at < @threshold }
    end
  end

  class Today < Base
    def initialize(threshold)
      super("today", I18n.t("gws/schedule/todo.header.today"))
      @threshold_from = threshold
      @threshold_to = threshold + 1.day
    end

    def name
      "#{super} - #{I18n.l(@threshold_from.to_date)}"
    end

    def collect(items)
      items.select { |item| @threshold_from <= item.end_at && item.end_at < @threshold_to }
    end
  end

  class Tomorrow < Base
    def initialize(threshold)
      super("tomorrow", I18n.t("gws/schedule/todo.header.tomorrow"))
      @threshold_from = threshold + 1.day
      @threshold_to = @threshold_from + 1.day
    end

    def name
      "#{super} - #{I18n.l(@threshold_from.to_date)}"
    end

    def collect(items)
      items.select { |item| @threshold_from <= item.end_at && item.end_at < @threshold_to }
    end
  end

  class DayAfterTomorrow < Base
    def initialize(threshold)
      super("day_after_tomorrow", I18n.t("gws/schedule/todo.header.day_after_tomorrow"))
      @threshold = threshold + 2.days
    end

    def collect(items)
      items.select { |item| @threshold <= item.end_at }
    end
  end

  class << self
    def get(type, threshold)
      case type
      when :out_dated
        OutDated.new(threshold)
      when :today
        Today.new(threshold)
      when :tomorrow
        Tomorrow.new(threshold)
      when :day_after_tomorrow
        DayAfterTomorrow.new(threshold)
      end
    end
  end
end
