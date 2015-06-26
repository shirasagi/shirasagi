class Ezine::Task
  include SS::Model::Task

  class << self
    public
      # Deliver a page as Emails.
      #
      # 1ページをメールとして送信する。
      # 配信予約日時が設定されている場合、条件を満たせば送信される。
      #
      # @param [Integer] page_id
      #
      #   ID of an Ezine::Page document.
      #
      #   Ezine::Page のドキュメントの ID。
      def deliver(page_id)
        page = Ezine::Page.where(completed: false, id: page_id).first
        return if page.nil?
        return if page.deliver_date && Time.zone.now < page.deliver_date
        ready(id: page.id, name: 'ezine:deliver') do |task|
          deliver_one_page page, task
        end
      end

      # Deliver reserved pages as Emails.
      #
      # 配信予約日時が入力されているページの中で、日時の条件を満たすページをメールとして送信する。
      def deliver_reserved
        time = Time.zone.now
        Ezine::Page.where(:completed => false, :deliver_date.ne => nil, :deliver_date.lte => time).each do |page|
          ready(id: page.id, name: 'ezine:deliver_reserved') do |task|
            deliver_one_page page, task
          end
        end
      end

    private
      # Deliver one page to one member as an Email.
      #
      # 1ページを複数メンバーにメールとして送信する。
      #
      # @param [Ezine::Page] page
      # @param [Ezine::Task] task
      def deliver_one_page(page, task)
        task.log "# Ezine::Page #{page.site.name} #{page.parent.name} #{page.name} start delivery"
        members = page.members_to_deliver
        result = Ezine::Result.new
        result.started = Time.zone.now
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
end
