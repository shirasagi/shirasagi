class Member::Agents::Nodes::LineFirstRegistrationController < ApplicationController
  include Cms::NodeFilter::View
  include Member::Line::LoginFilter
  include Cms::PublicFilter::Crud

  model Cms::Member
  helper Member::MypageHelper

  before_action :set_item
  skip_before_action :redirect_first_registration

  prepend_view_path "app/views/member/agents/nodes/my_line_profile"

  private

  def set_item
    @item = @cur_member
    @mypage_node = Member::Node::Mypage.site(@cur_site).first
  end

  def fix_params
    { first_registered: Time.zone.now }
  end

  public

  def index
    return if request.get?
    return if @mypage_node.nil?

    @item.attributes = get_params
    if @item.update
      respond_to do |format|
        format.html { redirect_to(@mypage_node.url) }
      end
    else
      respond_to do |format|
        format.html { render({ action: :index }) }
      end
    end
  end
end
