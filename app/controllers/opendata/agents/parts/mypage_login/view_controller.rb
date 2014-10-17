module Opendata::Agents::Parts::MypageLogin
  class ViewController < ApplicationController
    include Cms::PartFilter::View
    include Opendata::MypageFilter

    skip_filter :logged_in?

    public
      def index
        logged_in? redirect: false
        render
      end
  end
end
