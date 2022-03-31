class Recommend::Agents::Parts::SimilarityController < ApplicationController
  include Cms::PartFilter::View
  helper Recommend::ListHelper

  def index
    path = @cur_path
    path += "index.html" if @cur_path =~ /\/$/

    @limit = @cur_part.limit
    @contents = Recommend::SimilarityScore.site(@cur_site).similarity(path).
      where(@cur_part.condition_hash).
      limit(@limit)
  end
end
