module Opendata::Parts::MypageLogin
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
