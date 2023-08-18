class Gws::UserFormColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::ColumnFilter

  navi_view 'gws/user_conf/navi'
  self.form_model = Gws::UserForm

  private

  def set_crumbs
    set_form
    @crumbs << [t("mongoid.models.gws/user"), gws_users_path]
    @crumbs << [t("mongoid.models.gws/user_form"), gws_user_form_path]
  end

  def set_form
    @cur_form ||= form_model.site(@cur_site).order_by(id: 1, created: 1).first
  end
end
