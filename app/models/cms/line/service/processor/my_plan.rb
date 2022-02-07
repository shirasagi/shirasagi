class Cms::Line::Service::Processor::MyPlan < Cms::Line::Service::Processor::Base
  def call
  end

  def event_dates_label(item, date)
    dates = item.event_dates.clustered.select { |dates| dates.include?(date) }.first
    return if dates.blank?
    dates = (dates.size == 1) ? [dates.first] : [dates.first, dates.last]
    dates = dates.map { |d| I18n.l(d.to_date, format: :long) }.join(I18n.t("event.date_range_delimiter"))
  end

  def start_messages
    date = Time.zone.today
    member = event_session.member

    bookmarked_ids = []
    bookmarked_ids = member.bookmarks.pluck(:content_id) if member

    cond = { "$and" => [ { event_dates: { "$in" => [ date ] } }, service.condition_hash ] }
    criteria = Cms::Page.site(site).where(cond).limit(service.limit)
    items = Pippi::EventUtils.sort_event_page_by_difference(criteria, "event_dates_today") do |item, sort_cond|
      sort_cond.unshift(bookmarked_ids.include?(item.id) ? 0 : 1)
    end

    if items.present?
      template = Cms::LineUtils.flex_carousel_template("今日の予定", items) do |item, opts|
        opts[:name] = item.name
        opts[:text] =  service.page_summary(item, event_dates: event_dates_label(item, date))
        opts[:image_url] = service.page_image_url(item)
        opts[:bookmark] = bookmarked_ids.include?(item.id)
        opts[:action] = {
          type: "uri",
          label: "ページを見る",
          uri: item.full_url
        }
      end
      [
        {
          type: "text",
          text: "以下のイベントが本日開催予定です。"
        },
        template,
      ]
    else
      [
        {
          type: "text",
          text: "今日の予定はありませんでした。"
        }
      ]
    end
  end
end
