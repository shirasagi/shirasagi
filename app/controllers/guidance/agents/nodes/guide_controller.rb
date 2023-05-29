class Guidance::Agents::Nodes::GuideController < ApplicationController
  include Cms::NodeFilter::View

  public

  def index
    # render
  end

  def results
    ids = params[:results].to_s rescue ''
    ids = ids.split(',')

    @items = @cur_node.guidance_results.select do |item|
      ids.include?(item.id.to_s)
    end
  end
end
