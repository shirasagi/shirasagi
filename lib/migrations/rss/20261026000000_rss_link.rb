class SS::Migration20261026000000
  include SS::Migration::Base

  depends_on "20261023000003"

  def change
    each_page do |item|
      next if item.rss_link.blank?

      rss_link = item.rss_link
      if UrlValidator.valid?(rss_link, absolute_path: true)
        rss_link = SS.follow_up_url_encode!(rss_link) rescue nil
      else
        rss_link = nil
      end
      next if rss_link && rss_link == item.rss_link

      if rss_link
        item.set(rss_link: rss_link)
      else
        item.unset(:rss_link)
      end
    end
  end

  private

  def each_page(&block)
    Rss::Page.all.exists(rss_link: true).tap do |criteria|
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        criteria.in(id: ids).to_a.each(&block)
      end
    end
    Rss::WeatherXmlPage.all.exists(rss_link: true).tap do |criteria|
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        criteria.in(id: ids).to_a.each(&block)
      end
    end
  end
end
