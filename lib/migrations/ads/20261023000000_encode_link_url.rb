class SS::Migration20261023000000
  include SS::Migration::Base

  depends_on "20260427000000"

  def change
    each_item do |item|
      next if item.link_url.blank?

      link_url = SS.safe_encode_url(item.link_url)
      next if link_url == item.link_url

      item.set(link_url: link_url)
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
