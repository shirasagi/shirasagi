module Cms::Line::TaskFilter
  extend ActiveSupport::Concern

  def deliver_message(item)
    @deliver_mode = "main"

    @task.log("start deliver #{item.name}")
    raise "not registered line channel_secret and channel_token at site" if item.site.line_client.nil?
    raise "message not published! (#{item.name})" if !item.public?

    case item.deliver_action
    when "broadcast"
      broadcast_to_members(item)
    when "multicast"
      members = item.extract_deliver_members.to_a
      @task.log("extract #{members.size} members")
      multicast_to_members(item, members)
    end
  end

  def deliver_test_message(item, test_members)
    @deliver_mode = "test"

    @task.log("start test deliver #{item.name}")
    raise "message not published! (#{item.name})" if !item.public?

    @task.log("extract #{test_members.size} test members")

    multicast_to_members(item, test_members)
  end

  def broadcast_to_members(item)
    create_statistic(item)

    Cms::SnsPostLog::LineDeliver.create_with(item) do |log|
      begin
        log.action = item.deliver_action
        log.deliver_mode = @deliver_mode

        @task.log("broadcast to members")
        res = @site.line_client.broadcast(item.line_messages)
        res_code = res.code
        res_body = res.body.force_encoding("utf-8")

        log.messages = item.line_messages
        log.response_code = res_code
        log.response_body = res_body
        log.request_id = res["X-Line-Request-Id"]
        raise "#{res_code} #{res_body}" if res_code !~ /^2\d\d$/
        log.state = "success"

        update_statistic(item, request_id: log.request_id)
      rescue => e
        Rails.logger.fatal("#broadcast failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        log.error = "broadcast failed: #{e.class} (#{e.message})"
      end
    end
  end

  def multicast_to_members(item, members)
    create_statistic(item)

    members.each_slice(Cms::Line.max_members_to).with_index do |members_to, seq|
      names = members_to.map(&:name)
      user_ids = members_to.map(&:oauth_id)

      Cms::SnsPostLog::LineDeliver.create_with(item) do |log|
        begin
          log.action = item.deliver_action
          log.multicast_user_ids = user_ids
          log.deliver_mode = @deliver_mode
          log.in_members = members_to

          user_index = seq * Cms::Line.max_members_to
          @task.log("multicast to members #{user_index}..#{user_index + user_ids.size - 1}")
          names.each_with_index { |name, idx| @task.log("- #{user_ids[idx]} #{name}") }

          payload = multicast_payload(item)
          res = @site.line_client.multicast(user_ids, item.line_messages, payload: payload)
          res_code = res.code
          res_body = res.body.force_encoding("utf-8")

          log.messages = item.line_messages
          log.response_code = res_code
          log.response_body = res_body
          log.request_id = res["X-Line-Request-Id"]
          raise "#{res_code} #{res_body}" if res_code !~ /^2\d\d$/
          log.state = "success"

          update_statistic(item, member_count: user_ids.size)
        rescue => e
          Rails.logger.fatal("multicast failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
          log.error = "multicast failed: #{e.class} (#{e.message})"
        end
      end
    end
  end

  def multicast_payload(item)
    payload = {}
    if @deliver_mode == "main" && @statistic
      payload["customAggregationUnits"] = [@statistic.aggregation_unit]
    end
    payload
  end

  def create_statistic(item)
    return if @deliver_mode != "main"
    return if item.statistic_disabled?

    begin
      @statistic = Cms::Line::Statistic.create_from_message(item)
    rescue => e
      Rails.logger.fatal("create statistic failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @statistic = nil
    end
  end

  def update_statistic(item, request_id: nil, member_count: 0)
    return if @statistic.nil?
    now = Time.zone.now
    @statistic.request_id = request_id
    @statistic.member_count += member_count
    @statistic.update!
  end
end
