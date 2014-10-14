module Cms::PartFilter::View
  extend ActiveSupport::Concern
  include SS::AgentFilter

  included do
    helper ApplicationHelper
    before_action :prepend_current_view_path
  end

  private
    def prepend_current_view_path
      prepend_view_path "app/views/" + self.class.to_s.underscore.sub(/_\w+$/, "")
    end
end
