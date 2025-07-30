class Cms::Form::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::ColumnFilter2

  model Cms::Column::Base
  self.form_model = Cms::Form

  navi_view "cms/form/main/navi"
  append_view_path 'app/views/cms/columns2'

  # helper_method :column_type_options, :form_is_in_use?

  private

  def set_deletable
    @deletable ||= @cur_form.allowed?(:delete, @cur_user, site: @cur_site, owned: true)
  end

  def set_crumbs
    @crumbs << [Cms::Form.model_name.human, cms_forms_path]
    @crumbs << [cur_form.name, cms_form_path(id: cur_form)]
    @crumbs << [Cms::Column::Base.model_name.human, action: :index]
  end
end
