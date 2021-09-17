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

  def column_form
    set_item
  end

  def delete
    raise "404" if form_is_in_use?
    super
  end

  def destroy
    raise "404" if form_is_in_use?
    super
  end
end
