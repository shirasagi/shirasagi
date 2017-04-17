module Ezine::BaseJob
  extend ActiveSupport::Concern

  # Deliver one page to members as Emails.
  #
  # 1ページを複数メンバーにメールとして送信する。
  #
  def deliver_one_page(page, task)
    task.log "# Ezine::Page #{page.site.name} #{page.parent.name} #{page.name} start delivery"
    members = page.members_to_deliver
    result = Ezine::Result.new
    result.started = Time.zone.now
    success_count = 0
    Rails.logger.info("delivering to #{members.count} members")
    members.each.with_index do |member, index|
      interval_sleep index
      begin
        task.log "To: " + member.email
        page.deliver_to member
        success_count += 1
      rescue => e
        task.log "-- Error"
        task.log e.to_s
        task.log e.backtrace.join("\n")
      end
    end
    result.delivered = Time.zone.now
    result.count = success_count
    page.results << result
    page.completed = true if members.count == success_count
    if !page.update
      task.log "error: " + errors.full_messages.join(', ')
    end
    task.log "# Ezine::Page #{page.site.name} #{page.parent.name} #{page.name} finish delivery"
  end

  def interval_sleep(index)
    if index != 0 && index % SS.config.ezine.interval == 0
      sleep SS.config.ezine.sleep_seconds
    end
  end
end
