class SS::Migration20261023000000
  include SS::Migration::Base

  depends_on "20261009000000"

  def change
    each_item do |item|
      link_url = item.link_url
      next if link_url.blank?

      if UrlValidator.valid?(link_url, absolute_path: true)
        link_url = SS.follow_up_url_encode!(link_url) rescue nil
      else
        link_url = nil
      end
      next if link_url && link_url == item.link_url

      if link_url
        item.set(link_url: link_url)
      else
        item.unset(:link_url)
      end
    end
  end

  private

  def each_item(&block)
    criteria = Ads::Banner.all.exists(link_url: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
