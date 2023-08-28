class Cms::SyntaxChecker::SettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Site
  navi_view "cms/syntax_checker/main/conf_navi"
  before_action :set_addons

  private

  def set_crumbs
    @crumbs << [t("cms.syntax_check"), cms_syntax_checker_main_path]
    @crumbs << [t("cms.url_scheme"), url_for(action: :show)]
  end

  def set_item
    @item = @cur_site
  end

  def set_addons
    @addons = []
  end

  def get_params
    params.require(:item).permit(:syntax_check)
  rescue
    raise "400"
  end

  public

  def show
    raise "403" unless Cms::Tool.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def edit
    raise "403" unless Cms::Tool.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless Cms::Tool.allowed?(:read, @cur_user, site: @cur_site)
    render_update @item.save
  end
end
