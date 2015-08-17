module Cms::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Cms::User }

    helper Cms::NodeHelper
    helper Cms::FormHelper
    helper Cms::PathHelper
    before_action :set_site
    before_action :set_node
    before_action :set_group
    before_action :set_crumbs
  end

  private
    def set_site
      @cur_site = Cms::Site.find params[:site]
      @crumbs << [@cur_site.name, cms_contents_path]
    end

    def set_node
      return unless params[:cid]
      @cur_node = Cms::Node.site(@cur_site).find params[:cid]
      @cur_node.parents.each {|node| @crumbs << [node.name, view_context.contents_path(node)] }
      @crumbs << [@cur_node.name, view_context.contents_path(@cur_node)]
    end

    def set_group
      cur_groups = @cur_user.groups.in(name: @cur_site.groups.pluck(:name).map{ |name| /^#{Regexp.escape(name)}(\/|$)/ })
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
