class Cms::Line::Service::Processor::Chat < Cms::Line::Service::Processor::Base
  def start_messages
    templates = []

    if node.first_text.present?
      templates << {
        type: "text",
        text: "どのような情報をお探しですか。"
      }
    end

    if node.first_suggest.present?
      suggests = node.first_suggest
      actions = suggests.each_slice(4).to_a
      action_templates = []
      suggest_templates = []
      actions.each do |action|
        action.each do |suggest|
          suggest_templates << {
            type: "message",
            label: suggest,
            text: suggest
          }
        end
        action_templates << suggest_templates
        suggest_templates = []
      end

      templates += action_templates.map do |action|
        {
          type: "template",
          altText: "以下よりご選択ください。",
          template: {
            type: "buttons",
            actions: action,
            text: "以下よりご選択ください。",
          }
        }
      end
    end

    if templates.present?
      templates
    else
      super
    end
  end

  def node
    Cms::Node.find(1705)
  end

  def intent
    @intent
  end

  def find_intent(event)
    @intent = Chat::Intent.site(site).where(node_id: node.id).where(phrase: event.message['text']).first
  end

  def call
    events.each do |event|
      save_linebot_user(event)
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          find_intent(event)
          if event.message["text"] == node.set_location
            #reply_send_location(event)
          elsif intent
            if intent.suggest.present?
              reply_intent_suggests(event)
            elsif intent.link.present?
              reply_intent_links(event)
            elsif intent.response.present?
              reply_intent_response(event)
            else
              reply_no_match(event)
            end
          else
            reply_no_match(event)
          end

          save_linebot_phrase(event)
        when Line::Bot::Event::MessageType::Location
          #client.reply_message(event["replyToken"], select_info(event))
        end
      when Line::Bot::Event::Postback
        #reply_confirm(event)
      end
    end
  end

  # save session_user
  def save_linebot_user(event)
    # save Session
    item = Chat::LineBot::Session.new
    item.site = site
    item.node = node
    item.line_user_id = event['source']['userId']
    item.date_created = Time.zone.today
    item.save

    # save UsedTime
    item = Chat::LineBot::UsedTime.new
    item.site = site
    item.node = node
    item.hour = Time.zone.now.hour
    item.save
  end

  # reply intent suggests
  def reply_intent_suggests(event)
    suggests = intent.suggest
    actions = suggests.each_slice(4).to_a
    action_templates = []
    suggest_templates = []
    actions.each do |action|
      action.each do |suggest|
        suggest_templates << {
          "type": "message",
          "label": suggest,
          "text": suggest
        }
      end
      action_templates << suggest_templates
      suggest_templates = []
    end

    templates = []
    action_templates.each do |action|
      template =
        {
          "type": "template",
          "altText": suggest_text(event, templates),
          "template": {
            "type": "buttons",
            "actions": action,
            "text": suggest_text(event, templates)
          }
        }
      templates << template
    end
    templates << site_search(event) if intent.site_search == "enabled" && site_search?
    templates << question(event) if intent.question == "enabled" && question?
    client.reply_message(event["replyToken"], templates)
  end

  def suggest_text(event, templates)
    if templates.empty?
      if intent.suggest.present? && intent.response.present?
        intent.response.gsub(%r{</?[^>]+?>}, "")
      else
        node.response_template.gsub(%r{</?[^>]+?>}, "")
      end
    else
      I18n.t("chat.line_bot.service.choices") + (templates.length + 1).to_s
    end
  end

  # reply intent links
  def reply_intent_links(event)
    labels = intent.response.scan(/<a(?: .+?)?>.*?<\/a>/)
    actions = labels.each_slice(4).to_a
    links = intent.link.each_slice(4).to_a
    action_templates = []
    link_templates = []
    actions.zip(links).each do |action, link|
      action.zip(link).each do |label, url|
        link_templates << {
          "type": "uri",
          "label": label.gsub(%r{</?[^>]+?>}, ""),
          "uri": url
        }
      end
      action_templates << link_templates
      link_templates = []
    end

    templates = []
    action_templates.each do |action|
      template =
        {
          "type": "template",
          "altText": link_text(event, templates),
          "template": {
            "type": "buttons",
            "actions": action,
            "text": link_text(event, templates)
          }
        }
      templates << template
    end
    templates << site_search(event) if intent.site_search == "enabled" && site_search?
    templates << question(event) if intent.question == "enabled" && question?
    client.reply_message(event["replyToken"], templates)
  end

  def link_text(event, templates)
    if templates.empty?
      if intent.response.scan(/<p(?: .+?)?>.*?<\/p>/).present?
        intent.response.scan(/<p(?: .+?)?>.*?<\/p>/).join("").gsub(%r{</?[^>]+?>}, "")
      else
        node.response_template.gsub(%r{</?[^>]+?>}, "")
      end
    else
      I18n.t("chat.line_bot.service.choices") + (templates.length + 1).to_s
    end
  end

  # reply intent response
  def reply_intent_response(event)
    templates = []
    template =
      {
        "type": "text",
        "text": intent.response.gsub(%r{</?[^>]+?>}, "")
      }
    templates << template
    templates << site_search(event) if intent.site_search == "enabled" && site_search?
    templates << question(event) if intent.question == "enabled" && question?
    client.reply_message(event["replyToken"], templates)
  end

  # reply send location message
  def reply_send_location(event)
    client.reply_message(event["replyToken"], {
      "type": "template",
      "altText": I18n.t("chat.line_bot.service.send_location"),
      "template": {
        "type": "buttons",
        "text": I18n.t("chat.line_bot.service.send_location"),
        "actions": [
          {
            "type": "uri",
            "label": I18n.t("chat.line_bot.service.set_location"),
            "uri": "line://nv/location"
          }
        ]
      }
    })
  end

  # reply no match message
  def reply_no_match(event)
    template = []
    template << {
      "type": "text",
      "text": node.exception_text.gsub(%r{</?[^>]+?>}, "")
    }
    template << site_search(event) if site_search?
    client.reply_message(event["replyToken"], template)
  end

  def question(event)
    {
      "type": "template",
      "altText": node.question.gsub(%r{</?[^>]+?>}, ""),
      "template": {
        "type": "confirm",
        "text": node.question.gsub(%r{</?[^>]+?>}, ""),
        "actions": [
          {
            "type": "postback",
            "label": I18n.t("chat.line_bot.service.success"),
            "data": "yes, #{event.message['text']}"
          },
          {
            "type": "postback",
            "label": I18n.t("chat.line_bot.service.retry"),
            "data": "no, #{event.message['text']}"
          }
        ]
      }
    }
  end

  def question?
    node.question.present? && node.chat_success.present? && node.chat_retry.present?
  end

  def site_search(event)
    site_search_node = Cms::Node::SiteSearch.site(site).first
    uri = URI.parse(site_search_node.url)
    uri.query = {s: {keyword: event.message["text"]}}.to_query
    url = uri.try(:to_s)
    template = {
      "type": "template",
      "altText": I18n.t("chat.line_bot.service.site_search"),
      "template": {
        "type": "buttons",
        "text": I18n.t("chat.line_bot.service.site_search"),
        "actions": [
          {
            "type": "uri",
            "label": I18n.t("chat.line_bot.service.search_results"),
            "uri": "https://" + site.domains.first + url
          }
        ]
      }
    }
    template
  end

  def site_search?
    Cms::Node::SiteSearch.site(site).and_public.first.present?
  end

  def save_linebot_phrase(event)
    # save ExistsPhrase
    if intent
      name = intent.name
      item = Chat::LineBot::ExistsPhrase.site(site).where(node_id: node.id).where(name: name).first
      item ||= Chat::LineBot::ExistsPhrase.new
      item.site = site
      item.node = node
      item.name = name
      item.frequency += 1
      item.save
    end

    # save RecordPhrase
    name = event.message["text"]
    item = Chat::LineBot::RecordPhrase.site(site).where(node_id: node.id).where(name: name).first
    item ||= Chat::LineBot::RecordPhrase.new
    item.site = site
    item.node = node
    item.name = name
    item.frequency += 1
    item.save
  end
end
