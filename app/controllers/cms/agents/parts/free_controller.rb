class Cms::Agents::Parts::FreeController < ApplicationController
  include Cms::PartFilter::View

  def index
    render inline: @cur_part.html
  end
end
