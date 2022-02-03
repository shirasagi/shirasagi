class Cms::Line::Service::Processor::MyPlan < Cms::Line::Service::Processor::Base
  def call
  end

  def extract_image_url(item)
    image_url = service.no_image.try(:full_url)
    if item.thumb
      image_url = item.thumb.full_url
    else
      html = item.form ? item.render_html : item.html
      src = SS::Html.extract_img_src(html.to_s, site.full_root_url)
      image_url = ::File.join(site.full_root_url, src) if src.present? && src.start_with?('/')
    end
    image_url
  end

  def extract_summary(item, date)
    summary = []
    dates = item.event_dates.clustered.select { |dates| dates.include?(date) }.first
    if dates.present?
      dates = (dates.size == 1) ? [dates.first] : [dates.first, dates.last]
      dates = dates.map { |d| I18n.l(d.to_date, format: :long) }.join(I18n.t("event.date_range_delimiter"))
      summary << "日時：#{dates}"
    end

    column_value = item.column_values.where(name: "内容").first
    if column_value
      value = column_value.value.to_s.gsub(/\n/, " ").truncate(60)
      summary << "内容：#{value}"
    end
    summary = summary.join("\n")
  end

  def start_messages
    date = Time.zone.today
    member = event_session.member

    bookmarked_ids = []
    bookmarked_ids = member.bookmarks.pluck(:content_id) if member

    cond = { "$and" => [ { event_dates: { "$in" => [ date ] } }, service.condition_hash(site: site) ] }
    criteria = Cms::Page.site(site).where(cond).limit(service.limit)
    items = Pippi::EventUtils.sort_event_page_by_difference(criteria, "event_dates_today") do |item, sort_cond|
      sort_cond.unshift(bookmarked_ids.include?(item.id) ? 0 : 1)
    end

    if items.present?
      template = Cms::LineUtils.flex_carousel_template("今日の予定", items) do |item, opts|
        opts[:name] = item.name
        opts[:text] =  extract_summary(item, date)
        opts[:image_url] = extract_image_url(item)
        opts[:bookmark] = bookmarked_ids.include?(item.id)
        opts[:action] = {
          "type": "uri",
          "label": "ページを見る",
          "uri": item.full_url
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
