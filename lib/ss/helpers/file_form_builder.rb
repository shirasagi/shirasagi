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

    id = options.fetch(:id, sanitize_to_id("#{@object_name}[#{method}_id]"))
    @template.content_tag(:div, class: "ss-file-field", id: id) do
      @template.output_buffer << @template.content_tag(:span, class: "dropdown") do
        @template.output_buffer << @template.link_to(I18n.t('ss.links.upload'), path, class: %w(ajax-box btn btn-file-upload))
        @template.output_buffer << @template.button_tag("▼", name: nil, type: "button", class: %w(btn dropdown-toggle))
        @template.output_buffer << @template.content_tag(:div, class: %w(dropdown-menu)) do
          @template.output_buffer << @template.link_to(I18n.t('ss.links.upload'), path, class: "dropdown-item")
          @template.output_buffer << @template.link_to(
            I18n.t('sns.user_file'), @template.sns_apis_user_files_path(user: cur_user), class: "dropdown-item")
          if ss_mode == :cms
            @template.output_buffer << @template.link_to(
              I18n.t('cms.file'), @template.cms_apis_files_path, class: "dropdown-item")
          end
        end
      end
      @template.output_buffer << " "
      @template.output_buffer << @template.content_tag(:span, file.try(:humanized_name), class: "humanized-name")
      @template.output_buffer << " "
      @template.output_buffer << @template.hidden_field_tag(
        "#{@object_name}[#{method}_id]", file.try(:id), id: nil, class: "file-id")
      @template.output_buffer << " "
      @template.output_buffer << @template.link_to(
        "##{id}", class: [ 'btn-file-delete', file.blank? ? "hide" : nil ]
      ) do
        @template.content_tag(:i, "&#xE872;".html_safe, class: "material-icons", style: "font-size: 120%;")
      end
      @template.output_buffer << @template.content_tag(
        :span, I18n.t("ss.notice.file_droppable"), class: [ "upload-drop-notice", file.blank? ? nil : "hide" ]
      )
    end
  end
end
