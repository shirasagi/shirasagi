class SS::Migration20220526000000
  include SS::Migration::Base

  depends_on "20220510000000"

  def change
    each_page do |page|
      next if page.site.blank?

      if page.event_dates.blank?
        page.unset(:event_dates)
        next
      end

      recurrences = page.event_dates.clustered.map do |dates|
        { kind: "date", start_at: dates.first, frequency: "daily", until_on: dates.last }
      end

      page.event_recurrences = recurrences
      result = page.without_record_timestamps { page.save }
      unless result
        puts page.errors.full_messages.join("\n")
        Rails.logger.error { page.errors.full_messages.join("\n") }
      end
    end
  end

  private

  def each_page(&block)
    criteria = Cms::Page.all
    criteria = criteria.exists(event_dates: true)
    criteria = criteria.exists(event_recurrences: false)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
