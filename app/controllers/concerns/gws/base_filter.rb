module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Gws::User }

    before_action :set_assets
    before_action :set_cur_org
    before_action :set_group
    before_action :set_crumbs
    navi_view "gws/main/navi"
  end

  private
    def current_group
      @cur_group
    end

    def current_organization
      @cur_org
    end

    def set_crumbs
      #
    end

    def set_assets
      javascript 'gws/script'
      stylesheet 'gws/style'
    end

    # Set the instance variable of `@cur_org`.
    # When a request path is `/..g123/schedule/plan/new`, `group` becomes
    # `123` and set `SS::Group` instance whose ID is 123 to `@cur_org`.
    def set_cur_org
      @cur_org = SS::Group.find params[:group]
      raise "404" unless @cur_org
      @crumbs << [@cur_org.name, gws_portal_path]
    end

    # Set current user's group by `@cur_org`.
    def set_group
      cur_groups = @cur_user.groups.in(name: /^#{@cur_org.name}(\/|$)/)
      @cur_group = cur_groups.first # select one group
      raise "403" unless @cur_group
    end
end
