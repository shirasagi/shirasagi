module Cms::Agents::Parts::Free
  class ViewController < ApplicationController
    include Cms::PartFilter::View

    def index
      render inline: @cur_part.html
    end
  end
end
