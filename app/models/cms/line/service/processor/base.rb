class Cms::Line::Service::Processor::Base
  include ActiveModel::Model

  attr_accessor :service
  attr_accessor :site, :node, :client
  attr_accessor :request, :body
  attr_accessor :signature, :events
  attr_accessor :event_session

  def call
  end

  def start
    events.each do |event|
      client.reply_message(event["replyToken"], start_messages)
    end
  end

  def start_messages
    [
      {
        type: "text",
        text: "「#{service.name}」に切り替わりました。"
      }
    ]
  end

  def parse_request
    self.signature = request.env["HTTP_X_LINE_SIGNATURE"]
    self.body = request.body.read
    self.events = client.parse_events_from(body) rescue nil
  end

  def valid_signature?
    client.validate_signature(body, signature)
  end

  def webhook_verify_request?
    @events.blank?
  end

  def channel_user_id(event)
    event["source"]["userId"] rescue nil
  end

  def richmenu_switched?(event)
    return false if event["type"] != "postback"
    params = event["postback"]["params"]
    return false if params.blank?
    params["newRichMenuAliasId"].present?
  end

  def call
  end
end
