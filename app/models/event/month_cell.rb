class Event::MonthCell
  include SS::Liquidization

  attr_accessor :node, :request_month,
    :date, :year, :month, :day,
    :categories, :category_hash, :events

  def initialize(node, request_month, date, categories)
    @node = node
    @request_month = request_month

    @date = date
    @year = date.year
    @month = date.month
    @day = date.day

    @categories = categories
    @category_hash = categories.index_by(&:id)
    @events = []
  end

  def add(page)
    categories = page.category_ids.map { |id| category_hash[id] }.compact.sort_by(&:order)
    @events << Event.new(date, page, categories)
  end

  def holiday?
    date.national_holiday?
  end

  def holiday_name
    HolidayJapan.name(date)
  end

  def substitute_html
    ApplicationController.helpers.sanitize(node.substitute_html)
  end

  def current_month?
    month == request_month
  end

  def active?
    ::Event::Agents::Nodes::PageController.helpers.within_one_year?(date)
  end

  def daily_url
    sprintf("#{node.url}%04d%02d%02d/", year, month, day)
  end

  liquidize do
    export :node
    export :request_month
    export :date
    export :year
    export :month
    export :day
    export :events
    export :categories
    export :holiday?
    export :holiday_name
    export :substitute_html
    export :current_month?
    export :active?
    export :daily_url
  end

  def assigns
    %w(date year month day events categories holiday? holiday_name
      substitute_html request_month current_month? active? daily_url).map do |name|
        [name, send(name)]
    end.to_h
  end

  class Event
    include SS::Liquidization

    attr_accessor :date, :page, :categories

    def initialize(date, page, categories)
      @date = date
      @page = page
      @categories = categories
    end

    def name
      page.event_name.present? ? page.event_name : page.name
    end

    def category
      categories.first
    end

    def start_date
      page.event_dates.start_date(date) rescue nil
    end

    def end_date
      page.event_dates.end_date(date) rescue nil
    end

    def multiple_or_single_days
      page.event_dates.multiple_days?(date) ? 'multiple-days' : 'single-day'
    end

    def data_id
      categories.pluck(:id).join(" ")
    end

    def data_start_date
      start_date.strftime("%Y/%m/%d") rescue nil
    end

    def data_end_date
      end_date.strftime("%Y/%m/%d") rescue nil
    end

    delegate :url, :full_url, :event_dates, to: :page

    liquidize do
      export :page
      export :name
      export :url
      export :full_url
      export :event_dates
      export :categories
      export :category
      export :start_date
      export :end_date
      export :multiple_or_single_days
      export :data_id
      export :data_start_date
      export :data_end_date
    end
  end
end
