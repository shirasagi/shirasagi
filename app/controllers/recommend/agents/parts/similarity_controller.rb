class Recommend::Agents::Parts::SimilarityController < ApplicationController
  include Cms::PartFilter::View
  helper Recommend::ListHelper

  def index
    path = @cur_path
    path += "index.html" if @cur_path =~ /\/$/

    @limit = @cur_part.limit
    @items = Recommend::SimilarityScore.site(@cur_site).similarity(path).limit(@limit)
  end
end
