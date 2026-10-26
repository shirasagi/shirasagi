class SS::Migration20261026000001
  include SS::Migration::Base

  depends_on "20261023000003"

  def change
    each_page do |item|
      next if item.ical_link.blank?

      ical_link = item.ical_link
      if UrlValidator.valid?(ical_link, absolute_path: true)
        ical_link = SS.follow_up_url_encode!(ical_link) rescue nil
      else
        ical_link = nil
      end
      next if ical_link && ical_link == item.ical_link

      if ical_link
        item.set(ical_link: ical_link)
      else
        item.unset(:ical_link)
      end
    ensure
      FileUtils.rm_f(item.path)
    end
  end

  private

  def each_page(&block)
    criteria = Event::Page.all.exists(ical_link: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
