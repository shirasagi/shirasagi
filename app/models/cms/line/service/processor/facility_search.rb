class Cms::Line::Service::Processor::FacilitySearch < Cms::Line::Service::Processor::Base
  def call
    events.each do |event|
      if event["type"] == "message" && event["message"]["type"] == "text"
        reply_text_message(event)
      elsif event["type"] == "message" && event["message"]["type"] == "location"
        reply_facility_location(event)
      end
    end
  end

  def start_messages
    if service.categories.present?
      select_category_messages
    else
      not_found_messages
    end
  end

  def select_category_messages
    contents = []
    service.categories.each_with_index do |category, idx|
      contents << {
        type: "button",
        action: {
          type: "message",
          label: category.name,
          text: category.name
        },
      }
      if (idx + 1) != service.categories.size
        contents <<  { "type": "separator" }
      end
    end
    [
      {
        type: "text",
        text: "探したい施設を選んでください"
      },
      {
        type: "flex",
        altText: "探したい施設を選んでください",
        contents: {
          type: "bubble",
          size: "kilo",
            body: {
            type: "box",
            layout: "vertical",
            contents: contents,
          },
          styles: {
            body: {
              separator: true,
              separatorColor: "#000000"
            }
          }
        }
      }
    ]
  end

  def category_summary_messages(category)
    Cms::LineUtils.flex_carousel_template(category.name, category) do |item, opts|
      opts[:name] = item.name
      opts[:text] = item.summary
      opts[:image] = item.image
      opts[:action] = {
        type: "message",
        text: "#{item.name}を探す",
        label: item.name
      }
    end
  end

  def search_location_messages
    Cms::LineUtils.flex_carousel_template("位置情報の送信", nil) do |item, opts|
      opts[:name] = "位置情報の送信"
      opts[:text] = "1. マップ上の赤いピンで位置を指定します。\n2. 赤いピン上部の吹き出しの内の「位置情報を送信」をタップします。"
      opts[:action] = {
        type: "uri",
        label: "位置情報を送信する",
        uri: "https://line.me/R/nv/location/"
      }
    end
  end

  def facility_location_messages(category, locations)
    template = Cms::LineUtils.flex_carousel_template("#{category.name}を探す", locations) do |location, opts|
      item = location.item
      opts[:name] = location.item.name
      opts[:image_url] = category.page_image_url(item)
      opts[:text] = category.page_summary(item, distance: location.label)
      opts[:action] = {
        type: "uri",
        label: "ページを見る",
        uri: location.item.full_url
      }
    end
    [
      {
        type: "text",
        text: "以下の施設が見つかりました"
      },
      template
    ]
  end

  def not_found_messages
    [
      {
        type: "text",
        text: "施設が見つかりませんでした。"
      }
    ]
  end

  def reply_text_message(event)
    text = event["message"]["text"]

    service.categories.each do |category|
      if category.name == text
        reply_category_summary(event, category)
        break
      elsif "#{category.name}を探す" == text
        reply_search_category(event, category)
        break
      end
    end
  end

  def reply_category_summary(event, category)
    client.reply_message(event["replyToken"], category_summary_messages(category))
  end

  def reply_search_category(event, category)
    event_session.set_data(:category, category.id)
    client.reply_message(event["replyToken"], search_location_messages)
  end

  def reply_facility_location(event)
    lat = event["message"]["latitude"]
    lon = event["message"]["longitude"]

    category = service.categories.select do |item|
      item.id == event_session.get_data(:category)
    end.first

    locations = Map::Geolocation.where(category.condition_hash).
      geonear([lon, lat], category.limit)

    if locations.blank?
      client.reply_message(event['replyToken'], not_found_messages)
      return
    end
    client.reply_message(event["replyToken"], facility_location_messages(category, locations))
  end
end
