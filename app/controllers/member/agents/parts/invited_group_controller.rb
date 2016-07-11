class Member::Agents::Parts::InvitedGroupController < ApplicationController
  include Cms::PartFilter::View
  include Member::LoginFilter
  helper Cms::ListHelper

  skip_action_callback :logged_in?
  before_action :becomes_with_route
  before_action :set_member
  before_action :set_my_group_node

  private
    def becomes_with_route
      @cur_part = @cur_part.becomes_with_route
    end

    def set_member
      logged_in? redirect: false
      if @cur_member.blank?
        render text: ''
      end
    end

    def set_my_group_node
      @my_group_node = Member::Node::MyGroup.site(@cur_site).and_public.first
      if @my_group_node.blank?
        render text: ''
      end
    end

  public
    def index
      @items = Member::Group.site(@cur_site).and_invited(@cur_member).limit(20).order_by(created: 1)
    end
end
