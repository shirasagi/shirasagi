class Member::Agents::Parts::PhotoController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  public
    def index
      @items = Member::Photo.site(@cur_site).and_public(@cur_date).
        listable.where(@cur_part.condition_hash(cur_path: @cur_path)).
        order_by(@cur_part.sort_hash).
        limit(@cur_part.limit)
    end
end
