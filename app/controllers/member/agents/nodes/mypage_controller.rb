class Member::Agents::Nodes::MypageController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter

  def index
    if @cur_node.html.present?
      render
      return
    end

    child = @cur_node.children.first

    raise "404" unless child
    redirect_to child.url
  end
end
