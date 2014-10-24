module Cms::Agents::Parts::SnsShare
  class ViewController < ApplicationController
    include Cms::PartFilter::View

    def index
      render
    end
  end
end
