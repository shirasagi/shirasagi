module SS::Helpers::FileFormBuilder
  extend ActiveSupport::Concern
  include ActionView::Helpers::FormTagHelper

  def ss_file_field(method, options = {})
    if SS.file_upload_dialog == :v1
      ss_file_field_v1(method, options)
    else
      ss_file_field_v2(method, options)
    end
  end

  def ss_file_field_v1(method, options = {})
    component = SS::FileFieldComponent.new(item: @object, object_name: @object_name, object_method: method)
    @template.render component
  end

  def ss_file_field_v2(method, options = {})
    component = SS::FileFieldV2Component.new(item: @object, object_name: @object_name, object_method: method)
    @template.render component
  end
end
