class Cms::PageExpirationSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Page

  navi_view "cms/main/navi"

  helper_method :updated_before_options

  before_action :set_search_params

  private

  def set_crumbs
    @crumbs << [ t("cms.links.page_expiration_setting"), url_for(action: :index) ]
  end

  def permit_fields
    %i[expiration_setting_type]
  end

  def set_items
    @items = Cms::Page.all.site(@cur_site).allow(:edit, @cur_user, site: @cur_site)
  end

  def set_item
    item = Cms::Page.site(@cur_site).find(params[:id])
    @item = item.becomes_with_route
    # @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def updated_before_options
    I18n.t("cms.options.updated_before").map do |k, v|
      [ v, k.to_s.sub("_", ".") ]
    end
  end

  def set_search_params
    @s ||= OpenStruct.new(params[:s])
  end

  public

  def index
    raise "403" unless @cur_user.cms_role_permit_any?(@cur_site, :edit_cms_page_expiration_settings)
    set_items
    @items = @items.search(@s)
    if @s.expiration_setting_type.present?
      @items = @items.search_expiration_setting_type(expiration_setting_type: @s.expiration_setting_type)
    end
    if @s.updated_before.present?
      @items = @items.search_updated_before(updated_before: @s.updated_before)
    end
    @items = @items.page(params[:page]).per(50)
  end

  def show
    raise "403" unless @cur_user.cms_role_permit_any?(@cur_site, :edit_cms_page_expiration_settings)
    @addons = []
    render
  end

  def edit
    raise "403" unless @cur_user.cms_role_permit_any?(@cur_site, :edit_cms_page_expiration_settings)
    @addons = []
    render
  end

  def update
    raise "403" unless @cur_user.cms_role_permit_any?(@cur_site, :edit_cms_page_expiration_settings)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    result = @item.without_record_timestamps { @item.save }
    render_update result
  end
end
