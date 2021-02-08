class Opendata::Agents::Nodes::Mypage::Dataset::MyFavoriteDatasetController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  helper Opendata::UrlHelper
  helper Opendata::ListHelper

  before_action :set_model
  before_action :set_item, only: [:remove]

  append_view_path "app/views/opendata/agents/nodes/mypage/dataset/my_favorite_dataset"

  private

  def set_model
    @model = Opendata::DatasetFavorite
  end

  def set_item
    @item = @model.site(@cur_site).member(@cur_member).find params[:id]
  end

  public

  def index
    @items = []
    @model.site(@cur_site).member(@cur_member).order_by(updated: -1).each do |favorite|
      next if favorite.dataset.nil?
      @items << favorite
    end
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(20)
    render
  end

  def remove
    @item.destroy
    redirect_to @cur_node.url, notice: I18n.t("opendata.notice.remove_favorite")
  end
end
