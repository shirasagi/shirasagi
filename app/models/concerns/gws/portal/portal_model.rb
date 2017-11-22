module Gws::Portal::PortalModel
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    attr_accessor :portal_type
  end

  def my_portal?
    portal_type == :my_portal
  end

  def user_portal?
    portal_type == :user_portal
  end

  def group_portal?
    portal_type == :group_portal
  end

  def root_portal?
    portal_type == :root_portal
  end
end
