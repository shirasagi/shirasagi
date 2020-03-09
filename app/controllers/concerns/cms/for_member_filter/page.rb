module Cms::ForMemberFilter::Page
  extend ActiveSupport::Concern
  include Member::LoginFilter

  included do
    skip_before_action :logged_in?, unless: :for_member_enabled?
  end

  private

  def for_member_enabled?
    @cur_page.try(:for_member_enabled?) && !@preview
  end
end
