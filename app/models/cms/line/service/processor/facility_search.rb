class Cms::Line::Service::Processor::FacilitySearch < Cms::Line::Service::Processor::Base

  def flex_carousel_template(title, items)
    items = [items] if !items.is_a?(Array)

    contents = items.map do |item|
      opts = OpenStruct.new
      yield(item, opts)

      image = opts[:image]
      name = opts[:name].to_s
      text = opts[:text].to_s
      action = opts[:action]

      content = { type: "bubble", size: "kilo" }

      if image
        content[:hero] = {
          type: "image",
          url: image.full_url,
          size: "full",
          aspectRatio: "20:13",
          aspectMode: "cover"
        }
      end

      content[:body] = {
        type: "box",
        layout: "vertical",
        contents: []
      }

      # name
      content[:body][:contents] << {
        type: "text",
        text: name,
        wrap: true,
        weight: "bold",
        margin: "none"
      }

      # text
      text.split("\n").each_with_index do |line, idx|
        content[:body][:contents] << {
          type: "text",
          text: line,
          wrap: true,
          size: "sm",
          margin: (idx == 0) ? "md" : "none"
        }
      end

      # action
      if action
        content[:footer] = {
          type: "box",
          layout: "vertical",
          contents: [
            {
              type: "button",
              action: action,
              style: "secondary",
              margin: "none"
            }
          ]
        }
        content[:styles] = {
          footer: { separator: true }
        }
      end

      content
    end

    {
      type: "flex",
      altText: title,
      contents: {
        type: "carousel",
        contents: contents
      }
    }
  end

  def call
    events.each do |event|
      if event["type"] == "message" && event["message"]["type"] == "text"
        reply_text_message(event)
      elsif event["type"] == "message" && event["message"]["type"] == "location"
        reply_location(event)
      end
    end
  end

  def start_messages
    contents = []
    service.categories.each_with_index do |category, idx|
      contents << {
        "type": "button",
        "action": {
          "type": "message",
          "label": category.name,
          "text": category.name
        },
      }
      if (idx + 1) != service.categories.size
        contents <<  { "type": "separator" }
      end
    end

    [
      {
        "type": "text",
        "text": "探したい施設を選んでください"
      },
      {
        "type": "flex",
        "altText": "探したい施設を選んでください",
        "contents": {
          "type": "bubble",
          "size": "kilo",
            "body": {
            "type": "box",
            "layout": "vertical",
            "contents": contents,
          },
          "styles": {
            "body": {
              "separator": true,
              "separatorColor": "#000000"
            }
          }
        }
      }
    ]
  end

  def reply_text_message(event)
    text = event["message"]["text"]

    service.categories.each do |category|
      if category.name == text
        reply_category(event, category)
        break
      elsif "#{category.name}を探す" == text
        reply_search(event, category)
        break
      end
    end
  end

  def reply_category(event, category)
    template = flex_carousel_template(category.name, category) do |item, opts|
      opts[:name] = item.name
      opts[:text] = item.summary
      opts[:image] = item.image
      opts[:action] = {
        "type": "message",
        "text": "#{item.name}を探す",
        "label": item.name
      }
    end
    client.reply_message(event["replyToken"], template)
  end

  def reply_search(event, category)
    event_session.set_data(:category, category.id)
    template = flex_carousel_template("位置情報の送信", category) do |item, opts|
      opts[:name] = "位置情報の送信"
      opts[:text] = "1. マップ上の赤いピンで位置を指定します。\n2. 赤いピン上部の吹き出しの内の「位置情報を送信」をタップします。"
      opts[:action] = {
        "type": "uri",
        "label": "位置情報を送信する",
        "uri": "https://line.me/R/nv/location/"
      }
    end
    client.reply_message(event["replyToken"], template)
  end

  EARTH_RADIUS_KM = 6378.137

  def reply_location(event)
    lat = event["message"]["latitude"]
    lon = event["message"]["longitude"]

    category = service.categories.select do |item|
      item.id == event_session.get_data(:category)
    end.first
    category_ids = category ? category.category_ids : []

    query = {
      owner_item_type: "Facility::Node::Page",
      site_id: site.id,
      category_ids: { "$in" => category_ids }
    }
    query[:filename] = /^#{service.facility_node.filename}\// if service.facility_node

    pipes = []
    pipes << {
      '$geoNear' => {
        near: { type: "Point", coordinates: [ lon , lat ] },
        distanceField: "distance",
        query: query,
        spherical: true
      }
    }
    pipes << { '$limit' => 10 }
    items = Map::Geolocation.collection.aggregate(pipes).to_a
    items = items.map do |item|
      facility = Facility::Node::Page.find(item["owner_item_id"]) rescue nil
      next unless facility

      distance = item["distance"]
      if distance >= 1000
        distance = "#{(distance / 1000).round(1)} km"
      else
        distance = "#{distance.round(1)} m"
      end

      item["facility"] = facility
      item["distance"] = distance
      item
    end.compact

    if items.blank?
      client.reply_message(event['replyToken'], {
        "type": "text",
        "text": "施設が見つかりませんでした。"
      })
      return
    end

    template = flex_carousel_template("#{category.name}を探す", items) do |item, opts|
      opts[:name] = item["facility"].name
      opts[:text] = "距離：#{item["distance"]}\n#{facility_text(item["facility"])}"
      opts[:action] = {
        "type": "uri",
        "label": "ページを見る",
        "uri": item["facility"].full_url
      }
    end

    messages = [
      {
        "type": "text",
        "text": "以下の施設が見つかりました"
      },
      template
    ]
    client.reply_message(event["replyToken"], messages)
  end

  def facility_text(facility)
    text = []
    labels = I18n.t("mongoid.attributes.facility/node/page").map { |k, v| [v, k.to_s] }.to_h

    service.text_keys.each do |label|
      key = labels[label]
      if key
        text << "#{label}：#{facility.send(key)}"
      else
        add_info = facility.additional_info.select { |v| v[:field] == label }.first
        text << "#{label}：#{add_info[:value]}" if add_info
      end
    end
    text.join("\n")
  end
end
