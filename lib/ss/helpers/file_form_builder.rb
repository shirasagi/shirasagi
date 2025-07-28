module SS::Helpers::FileFormBuilder
  extend ActiveSupport::Concern
  include ActionView::Helpers::FormTagHelper

  def ss_file_field(method, accepts: nil)
    if SS.file_upload_dialog == :v1
      ss_file_field_v1(method, accepts: accepts)
    else
      ss_file_field_v2(method, accepts: accepts)
    end
  end

  def ss_file_field_v1(method, accepts: nil)
    # v1 では accepts をサポートできない。accepts をサポートするのは v2 のみ
    component = SS::FileFieldComponent.new(item: @object, object_name: @object_name, object_method: method)
    @template.render component
  end

  def ss_file_field_v2(method, accepts: nil)
    component = SS::FileFieldV2Component.new(item: @object, object_name: @object_name, object_method: method, accepts: accepts)
    @template.render component
  end
end
