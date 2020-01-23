module SS::Helpers::FileFormBuilder
  extend ActiveSupport::Concern

  def ss_file_field(method, options = {})
    ss_mode = @template.instance_variable_get(:"@ss_mode")
    # cur_site = @template.instance_variable_get(:"@cur_site")
    cur_user = @template.instance_variable_get(:"@cur_user")
    item = @template.instance_variable_get(:"@#{@object_name}")
    file = item.send(method)

    case ss_mode
    when :cms
      cur_node = @template.instance_variable_get(:"@cur_node")
      if cur_node
        path = @template.cms_apis_node_temp_files_path
      else
        path = @template.cms_apis_temp_files_path
      end
    else
      path = @template.sns_apis_temp_files_path(user: cur_user)
    end

    @template.content_tag(:div, class: "ss-file-field") do
      @template.output_buffer << @template.link_to(I18n.t('ss.links.upload'), path, class: %w(ajax-box btn btn-file-upload))
      @template.output_buffer << " "
      @template.output_buffer << @template.content_tag(:span, file.try(:humanized_name), class: "humanized-name")
      @template.output_buffer << " "
      @template.output_buffer << @template.hidden_field_tag(
        "#{@object_name}[#{method}_id]", file.try(:id), id: nil, class: "file-id")
      @template.output_buffer << " "
      @template.output_buffer << @template.link_to("#", class: 'btn-file-delete', style: file.present? ? nil : "display: none") do
        @template.content_tag(:i, "&#xE872;".html_safe, class: "material-icons", style: "font-size: 120%;")
      end
    end
  end
end
