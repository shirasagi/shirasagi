class Article::Agents::Nodes::FormExportController < ApplicationController
  include Cms::NodeFilter::View

  before_action :validate_filename

  private

  def validate_filename
    raise SS::NotFoundError unless @cur_node.resolve_filename == params[:filename]
    raise SS::NotFoundError unless %w(csv json).include?(params[:format])
  end

  def pages
    cond = { form_id: @cur_node.form_id }

    if @cur_node.node_id
      Article::Page.public_list(site: @cur_site, node: @cur_node.node, date: @cur_date).where(cond)
    else
      Article::Page.public_list(site: @cur_site, date: @cur_date).where(cond)
    end
  end

  public

  def index
    filename = "#{@cur_node.resolve_filename}.#{params[:format]}"

    respond_to do |format|
      format.csv { send_data @cur_node.pages_to_csv(pages), filename: filename }
      format.json { render json: @cur_node.pages_to_json(pages), filename: filename }
    end
  end
end
