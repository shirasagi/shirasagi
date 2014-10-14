module Article::Agents::Pages::Page
  class ViewController < ApplicationController
    include Cms::PageFilter::View
  end
end
