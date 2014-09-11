# coding: utf-8
module Opendata::Parts::MypageLogin
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Opendata::Part::MypageLogin
  end

  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    include Opendata::MypageFilter

    skip_filter :logged_in?

    public
      def index
        logged_in? redirect: false
        render
      end
  end
end
