class Cms::Agents::Parts::FreeController < ApplicationController
  include Cms::PartFilter::View

  def index
    render html: @cur_part.html.html_safe
  end
end
