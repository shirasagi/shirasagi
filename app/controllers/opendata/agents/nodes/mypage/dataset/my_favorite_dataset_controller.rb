class Opendata::Agents::Nodes::Mypage::Dataset::MyFavoriteDatasetController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  helper Opendata::UrlHelper
  helper Opendata::ListHelper

  before_action :set_model
  before_action :set_favorites

  append_view_path "app/views/opendata/agents/nodes/mypage/dataset/my_favorite_dataset"

  private

  def set_model
    @model = Opendata::Dataset
  end

  def set_favorites
    @favorites = Opendata::DatasetFavorite.site(@cur_site).
      member(@cur_member)
  end

  public

  def index
    dataset_ids = @favorites.pluck(:dataset_id)

    s = params.permit(s: [:sort, :keyword])[:s].presence || {}
    sort = @model.sort_hash(s[:sort])

    @items = @model.site(@cur_site).
      in(id: dataset_ids).
      search(s.merge(site: @cur_site)).
      order_by(sort).
      page(params[:page]).
      per(5)
  end

  def remove
    @favorites.where(dataset_id: params[:id]).destroy_all
    redirect_to @cur_node.url, notice: I18n.t("opendata.notice.remove_favorite")
  end
end
