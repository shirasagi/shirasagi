module Cms::PartFilter::View
  extend ActiveSupport::Concern
  include SS::AgentFilter

  included do
    helper ApplicationHelper
    before_action :prepend_current_view_path
    before_action :load_items_in_ajax
  end

  private

  def prepend_current_view_path
    prepend_view_path "app/views/" + self.class.to_s.underscore.sub(/_\w+$/, "")
  end

  # ajax_view が enabled の場合、いくつかの重要なメンバー変数が存在しないのでDBから読み込む
  def load_items_in_ajax
    return if @cur_part.ajax_view != "enabled"

    unless instance_variable_defined?(:@cur_page)
      @cur_page = cur_page
    end
    if @cur_page && @cur_page.site_id == @cur_site.id
      @cur_page.cur_site = @cur_site
      @cur_page.site = @cur_site
    end

    unless @cur_page
      unless instance_variable_defined?(:@cur_node)
        @cur_node = cur_node
      end
      if @cur_node && @cur_node.site_id == @cur_site.id
        @cur_node.cur_site = @cur_site
        @cur_node.site = @cur_site
      end
    end

    unless instance_variable_defined?(:@cur_item)
      @cur_item = @cur_page || @cur_node
    end
  end

  def cur_page
    return @cur_page if instance_variable_defined?(:@cur_page)
    @cur_page = Cms::Page.site(@cur_site).and_public(@cur_date).filename(@cur_main_path).first
  end

  def cur_node
    return @cur_node if instance_variable_defined?(:@cur_node)
    @cur_node = Cms::Node.site(@cur_site).and_public(@cur_date).in_path(@cur_main_path).reorder(depth: -1).first
  end
end
