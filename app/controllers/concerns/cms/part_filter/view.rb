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

  public
    def cur_node
      node = Cms::Node.site(@cur_site).in_path(@cur_path).sort(depth: -1).first
      return unless node
      @preview || node.public? ? node.becomes_with_route : nil
    end
end
