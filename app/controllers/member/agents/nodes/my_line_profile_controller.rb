class Member::Agents::Nodes::MyLineProfileController < ApplicationController
  include Cms::NodeFilter::View
  include Member::Line::LoginFilter
  include Cms::PublicFilter::Crud

  model Cms::Member
  helper Member::MypageHelper

  before_action :set_item

  prepend_view_path "app/views/member/agents/nodes/my_line_profile"

  private

  def set_item
    @item = @cur_member
  end

  public

  def index
  end

  def show
  end

  # 退会
  def leave
  end

  # 退会確認
  def confirm_leave
    # 戻るボタンがクリックされた
    if params[:back]
      redirect_to @cur_node.url
      return
    end
  end

  # 退会完了
  def complete_leave
    # 戻るボタンがクリックされた
    if params[:back]
      redirect_to @cur_node.url
      return
    end

    @item.delete_leave_member_data(@cur_site)
    clear_member
    @item.destroy
  end
end
