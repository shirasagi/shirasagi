class Ads::Agents::Parts::BannerController < ApplicationController
  include Cms::PartFilter::View

  def index
    @node = @cur_part.parent
    return head :ok unless @node

    cond = {}

    if @cur_part.with_category == "enabled"
      if cur_page && cur_page.categories.present?
        cond[:ads_category_ids.in] = cur_page.categories.pluck(:id)
      elsif cur_node && cur_node.route =~ /^category\//
        cond[:ads_category_ids.in] = [cur_node.id]
      end
    end

    sort = @cur_part.becomes_with_route.sort_hash
    @random = sort[:random]

    @items = Ads::Banner.site(@cur_site).node(@node).and_public(@cur_date).
      where(cond).
      order_by(sort)
  end
end
