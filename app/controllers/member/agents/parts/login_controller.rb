class Member::Agents::Parts::LoginController < ApplicationController
  include Cms::PartFilter::View
  include Member::AuthFilter

  def index
    @cur_member  = get_member_by_session(@cur_site)
    @login_node  = Member::Node::Login.site(@cur_site).first
    @mypage_node = Member::Node::Mypage.site(@cur_site).first
  end
end
