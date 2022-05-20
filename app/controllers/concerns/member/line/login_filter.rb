module Member::Line::LoginFilter
  extend ActiveSupport::Concern
  include Member::LoginFilter

  included do
    before_action :redirect_first_registration
  end

  def redirect_first_registration
    return if @cur_member.nil?
    return if @cur_member.first_registered

    @profile_node = Member::Node::LineFirstRegistration.site(@cur_site).first
    return if @profile_node.nil?
    redirect_to @profile_node.url
  end
end
