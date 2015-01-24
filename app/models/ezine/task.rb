class Ezine::Task
  include SS::Task::Model

  class << self
    public
      # Deliver a page as Emails.
      #
      # 1ページをメールとして送信する。
      #
      # @param [Integer] page_id
      #
      #   ID of an Ezine::Page document.
      #
      #   Ezine::Page のドキュメントの ID。
      def deliver(page_id)
        page = Ezine::Page.where(completed: false, id: page_id).first
        return if page.nil?
        ready(id: page.id, name: 'ezine:deliver') do |task|
          deliver_one_page page, task
        end
      end

      # Deliver all pages as Emails.
      #
      # 全てのページをメールとして送信する。
      def deliver_all
        Ezine::Page.where(completed: false).each do |page|
          ready(id: page.id, name: 'ezine:deliver_all') do |task|
            deliver_one_page page, task
          end
        end
      end

    private
      # Deliver one page to one member as an Email.
      #
      # 1ページを1メンバーにメールとして送信する。
      #
      # @param [Ezine::Page] page
      # @param [Ezine::Task] task
      def deliver_one_page(page, task)
        task.log "# Ezine::Page #{page.site.name} #{page.parent.name} #{page.name} start delivery"
        members = page.members_to_deliver
        page.results << Time.now # as started time
        success_count = 0
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
        page.results << Time.now # as finished time
        page.results << success_count
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
end
