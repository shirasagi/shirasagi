module Gws::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    cattr_accessor(:user_class) { Gws::User }

    before_action :set_assets
    before_action :set_site
    before_action :set_group
    before_action :set_crumbs
    navi_view "gws/main/navi"
  end

  private
    def set_assets
      javascript 'gws/script'
      stylesheet 'gws/style'
    end

    def set_site
      @ss_mode = :gws
      @cur_site = SS::Group.find params[:site]
      @crumbs << [@cur_site.name, gws_portal_path]
    end

    def set_group
      cur_groups = @cur_user.groups.in(name: /^#{@cur_site.name}(\/|$)/)
      @cur_group = cur_groups.first # select one group
      raise "403" unless @cur_group
    end

    def set_crumbs
      #
    end

    def current_site
      @cur_site
    end

    def current_group
      @cur_group
    end
end
