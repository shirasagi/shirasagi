# coding: utf-8
module Article::Pages::Page
  class ViewCell < Cell::Rails
    include Cms::PageFilter::ViewCell
  end
end
