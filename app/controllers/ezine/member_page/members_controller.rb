class Ezine::MemberPage::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Cms::Member

  append_view_path "app/views/cms/pages"
  navi_view "ezine/main/navi"

  def index
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).and_enabled.where(subscription_ids: @cur_node.id).
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).per(50)
  end
end
