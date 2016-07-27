class Opendata::Agents::Parts::Mypage::MypageLoginController < ApplicationController
  include Cms::PartFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  helper Opendata::UrlHelper

  skip_action_callback :logged_in?

  def index
    logged_in? redirect: false
    render
  end
end
