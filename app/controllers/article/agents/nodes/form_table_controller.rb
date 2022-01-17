class Article::Agents::Nodes::FormTableController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper
  include Cms::NodeFilter::ListView

  before_action :set_form

  private

  def set_form
    @form = @cur_node.form
  end

  def pages
    @cur_node.pages.public_list(site: @cur_site, date: @cur_date)
  end

  public

  def index
    @items = pages.
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)

    respond_to do |format|
      format.html do
        render_with_pagination @items
      end
      format.csv do
        send_data @cur_node.to_csv(@items), filename: "index.csv"
      end
    end
  end
end
