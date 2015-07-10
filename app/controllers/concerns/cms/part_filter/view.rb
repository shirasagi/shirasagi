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

    def cur_page
      return @cur_page if @cur_page
      path = @cur_path.sub(/^#{@cur_site.url}/, "")
      page = Cms::Page.site(@cur_site).filename(path).first
      page ? page.becomes_with_route : nil
    end

    def cur_node
      return @cur_node if @cur_node
      path = @cur_path.sub(/^#{@cur_site.url}/, "")
      node = Cms::Node.site(@cur_site).in_path(path).sort(depth: -1).first
      node ? node.becomes_with_route : nil
    end
end
