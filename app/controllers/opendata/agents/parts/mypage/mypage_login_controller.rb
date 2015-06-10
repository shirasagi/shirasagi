class Opendata::Agents::Parts::Mypage::MypageLoginController < ApplicationController
  include Cms::PartFilter::View
  include Opendata::Mypage::MypageFilter

  skip_filter :logged_in?

  public
    def index
      logged_in? redirect: false
      render
    end
end
