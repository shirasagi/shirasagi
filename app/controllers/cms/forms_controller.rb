class Cms::FormsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Form
  navi_view "cms/main/conf_navi"

  helper_method :form_is_in_use?

  private

  def set_crumbs
    @crumbs << [Cms::Form.model_name.human, action: :index]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def form_is_in_use?
    return @form_is_in_use if !@form_is_in_use.nil?

    set_item
    @form_is_in_use = Cms::Page.site(@cur_site).where(form_id: @item.id).present?
  end

  public

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    if @item.state == "closed" && form_is_in_use?
      @item.errors.add :base, :unable_to_close_form_if_form_is_in_use
      render_update false
      return
    end

    render_update @item.update
  end

  def delete
    raise "404" if form_is_in_use?
    super
  end

  def destroy
    raise "404" if form_is_in_use?
    super
  end

  def column_form
    set_item
  end
end
