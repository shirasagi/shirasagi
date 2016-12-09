module Cms::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Cms::User }

    helper Cms::NodeHelper
    helper Cms::FormHelper
    helper Cms::PathHelper
    helper Map::MapHelper
    before_action :set_cms_assets
    before_action :set_site
    before_action :set_node
    before_action :set_group
    before_action :set_crumbs
  end

  private
    def set_cms_assets
      SS.config.cms.stylesheets.each { |m| stylesheet(m) } if SS.config.cms.stylesheets.present?
      SS.config.cms.javascripts.each { |m| javascript(m) } if SS.config.cms.javascripts.present?
    end

    def set_site
      @ss_mode = :cms
      @cur_site = Cms::Site.find id: params[:site]
      request.env["ss.site"] = @cur_site
      @cur_site.cur_domain = request_host
      @crumbs << [@cur_site.name, cms_contents_path]
    end

    def set_node
      return unless params[:cid]
      @cur_node = Cms::Node.site(@cur_site).find params[:cid]
      @cur_node.parents.each {|node| @crumbs << [node.name, view_context.contents_path(node)] }
      @crumbs << [@cur_node.name, view_context.contents_path(@cur_node)]
    end

    def set_group
      names = @cur_site.groups.active.pluck(:name).map { |name| /^#{Regexp.escape(name)}(\/|$)/ }
      cur_groups = @cur_user.groups.active.in(name: names)
      @cur_group = cur_groups.first # select one group
      raise "403" unless @cur_group
    end

    def set_crumbs
      #
    end
end
