class Recommend::Agents::Parts::SimilarityController < ApplicationController
  include Cms::PartFilter::View
  include Recommend::ContentFilter
  helper Cms::ListHelper

  def index
    path = @cur_path
    path += "index.html" if @cur_path.end_with?('/')

    @contents = Recommend::SimilarityScore.site(@cur_site).similarity(path).
      where(@cur_part.condition_hash).
      limit(100)
    set_items
  end
end
