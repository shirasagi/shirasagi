class Cms::Agents::Tasks::Line::MessagesController < ApplicationController
  include Cms::Line::TaskFilter

  def deliver
    if @message.nil?
      @task.log "message not found!"
      head :ok
      return
    end

    now = Time.zone.now
    begin
      pull_private_files(@message)
      deliver_message(@message)
    rescue => e
      @task.log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    ensure
      @message.complete_delivery(now)
    end
    head :ok
  end

  def test_deliver
    if @message.nil? || @test_members.blank?
      @task.log "message or test members not found!"
      head :ok
      return
    end

    now = Time.zone.now
    begin
      pull_private_files(@message)
      deliver_test_message(@message, @test_members)
    rescue => e
      @task.log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    ensure
      @message.complete_test_delivery(now)
    end
    head :ok
  end

  def reserve_deliver
    now = Time.zone.now
    messages = Cms::Line::Message.site(@site).where(deliver_state: "ready")
    plans = Cms::Line::DeliverPlan.site(@site).in(message_id: messages.pluck(:id)).where(
      :state => "ready",
      :deliver_date.ne => nil,
      :deliver_date.lte => now
    ).to_a
    messages = plans.map { |plan| plan.message  }.uniq { |message| message.id }

    messages.each do |message|
      begin
        pull_private_files(message)
        message.publish
        deliver_message(message)
      rescue => e
        @task.log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      ensure
        message.complete_delivery(now)
      end
    end
    head :ok
  end

  def pull_private_files(message)
    return unless SS::Lgwan.enabled?
    message.templates.each { |template| SS::Lgwan.pull_private_files(template) }
  end
end
