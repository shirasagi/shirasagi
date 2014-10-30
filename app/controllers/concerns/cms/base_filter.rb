module Cms::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    helper Cms::NodeHelper
    helper Cms::FormHelper
    before_action :set_site
    before_action :set_node
    before_action :set_group
    before_action :set_crumbs
  end

  private
    def set_site
      @cur_site = SS::Site.find_by host: params[:site]
      @crumbs << [@cur_site.name, cms_main_path]
    end

    def set_node
      return unless params[:cid]
      @cur_node = Cms::Node.site(@cur_site).find params[:cid]
      @cur_node.parents.each {|node| @crumbs << [node.name, view_context.contents_path(node)] }
      @crumbs << [@cur_node.name, view_context.contents_path(@cur_node)]
    end

    def set_group
      cur_groups = @cur_user.groups.in(name: @cur_site.groups.pluck(:name).map{ |name| /^#{name}(\/|$)/ })
      @cur_group = cur_groups.first # select one group
      raise "403" unless @cur_group
    end

    def set_crumbs
      #
    end

  public
    #def url_options
    #  {}.merge(super)
    #end
end
