module History::DiffHelper
  def diff_before_value(str1, str2)
    sdiffs = Diff::LCS.sdiff(str1, str2).collect do |sdiff|
      value = ERB::Util.html_escape(sdiff.old_element)
      case sdiff.action
      when '+'
        "<span class='add'>#{value}</span>"
      when '-'
        "<span class='delete'>#{value}</span>"
      when '!'
        "<span class='change'>#{value}</span>"
      else
        value
      end
    end
    sdiffs.join('').html_safe
  end

  def diff_current_value(str1, str2)
    sdiffs = Diff::LCS.sdiff(str1, str2).collect do |sdiff|
      value = ERB::Util.html_escape(sdiff.old_element)
      case sdiff.action
      when '+'
        "<span class='delete'>#{value}</span>"
      when '-'
        "<span class='add'>#{value}</span>"
      when '!'
        "<span class='change'>#{value}</span>"
      else
        value
      end
    end
    sdiffs.join('').html_safe
  end

  def column_values_diff(array1, array2)
    array1 ||= []
    array2 ||= []
    html = []
    array1.each_with_index do |column_value, i|
      current_value = array2.find do |data|
        column_value['column_id'] == data['column_id'] && column_value['order'] == data['order']
      end

      case column_value['_type']
      when 'Cms::Column::Value::CheckBox'
        before_value = column_value_check_box_diff_text(column_value)
        current_value = column_value_check_box_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      when 'Cms::Column::Value::DateField'
        before_value = column_value_date_field_diff_text(column_value)
        current_value = column_value_date_field_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      when 'Cms::Column::Value::FileUpload'
        before_value = column_value_file_upload_diff_text(column_value)
        current_value = column_value_file_upload_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      when 'Cms::Column::Value::Free', 'Cms::Column::Value::Table', 'Cms::Column::Value::TextArea',
        'Cms::Column::Value::TextField', 'Cms::Column::Value::RadioButton', 'Cms::Column::Value::Select'
        before_value = column_value_base_diff_text(column_value)
        current_value = column_value_base_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      when 'Cms::Column::Value::Headline'
        before_value = column_value_headline_diff_text(column_value)
        current_value = column_value_headline_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      when 'Cms::Column::Value::List'
        before_value = column_value_list_diff_text(column_value)
        current_value = column_value_list_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      when 'Cms::Column::Value::UrlField2'
        before_value = column_value_url_field2_diff_text(column_value)
        current_value = column_value_url_field2_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      when 'Cms::Column::Value::Youtube'
        before_value = column_value_youtube_diff_text(column_value)
        current_value = column_value_youtube_diff_text(current_value)
        html << column_value_diff_html(column_value['name'], before_value, current_value)
      else
        html << "<tr>"
        html << "  <th>#{column_value['name']}</th>"
        html << "  <td class='diff'>#{column_value.present? ? column_value.inspect : ""}</td>"
        html << "  <td class='diff'>#{current_value.present? ? current_value.inspect : ""}</td>"
        html << "</tr>"
      end
    end
    array2.each_with_index do |column_value, i|
      before_value = array1.find do |data|
        column_value['column_id'] == data['column_id'] && column_value['order'] == data['order']
      end

      next if before_value.present?

      case column_value['_type']
      when 'Cms::Column::Value::CheckBox'
        current_value = column_value_check_box_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      when 'Cms::Column::Value::DateField'
        current_value = column_value_date_field_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      when 'Cms::Column::Value::FileUpload'
        current_value = column_value_file_upload_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      when 'Cms::Column::Value::Free', 'Cms::Column::Value::Table', 'Cms::Column::Value::TextArea',
        'Cms::Column::Value::TextField', 'Cms::Column::Value::RadioButton', 'Cms::Column::Value::Select'
        current_value = column_value_base_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      when 'Cms::Column::Value::Headline'
        current_value = column_value_headline_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      when 'Cms::Column::Value::List'
        current_value = column_value_list_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      when 'Cms::Column::Value::UrlField2'
        current_value = column_value_url_field2_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      when 'Cms::Column::Value::Youtube'
        current_value = column_value_youtube_diff_text(column_value)
        html << column_value_diff_html(column_value['name'], '', current_value)
      else
        html << "<tr>"
        html << "  <th>#{column_value['name']}</th>"
        html << "  <td class='diff'></td>"
        html << "  <td class='diff'>#{column_value.present? ? column_value.inspect : ""}</td>"
        html << "</tr>"
      end
    end
    html.join('').html_safe
  end

  def column_value_base_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(item, 'value')
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_check_box_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(
      item, 'values',
      item['values'].join("、")
    )
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_date_field_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(
      item, 'date',
      I18n.l(item['date'], format: :long)
    )
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_file_upload_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(item, 'file_label')
    html << column_value_diff_text(
      item, 'image_html_type',
      I18n.t("cms.options.column_image_html_type.#{item['image_html_type']}")
    )
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_headline_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(item, 'head')
    html << column_value_diff_text(item, 'text')
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_list_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(
      item, 'lists',
      item['lists'].join("、")
    )
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_url_field2_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(item, 'link_label')
    html << column_value_diff_text(item, 'link_url')
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_youtube_diff_text(item)
    return '' if item.blank?

    html = []
    html << column_value_diff_text(item, 'url')
    html << column_value_diff_text(item, 'width')
    html << column_value_diff_text(item, 'height')
    html << column_value_diff_text(
      item, 'alignment',
      I18n.t("cms.options.alignment.#{item['alignment']}")
    )
    html.reject(&:blank?).join(',')
  end

  def column_value_diff_html(name, before_value, current_value)
    return '' if before_value == current_value

    html = []
    html << "<tr>"
    html << "  <th>#{name}</th>"
    html << "  <td>#{diff_before_value(before_value, current_value)}</td>"
    html << "  <td>#{diff_current_value(current_value, before_value)}</td>"
    html << "</tr>"
    html.join('').html_safe
  end

  def column_value_diff_text(item, key, value = nil)
    return '' if item.blank? || item[key].blank?
    value ||= item[key]
    "#{item['_type'].constantize.t(key)}: #{value}"
  end
end
