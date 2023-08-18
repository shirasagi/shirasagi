class Gws::UserFormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::UserForm

  navi_view 'gws/user_conf/navi'

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/user"), gws_users_path]
    @crumbs << [t("mongoid.models.gws/user_form"), gws_user_form_path]
  end

  def set_item
    @item ||= @model.site(@cur_site).order_by(id: 1, created: 1).first_or_create
  end
end
