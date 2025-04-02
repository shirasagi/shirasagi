#frozen_string_literal: true

class SS::TempFileViewComponent < SS::FileViewComponent
  FILE_ATTRIBUTES = %i[id name humanized_name extname url image? thumb_url image_dimension].freeze

  def file_view_tag_data
    data_hash = FILE_ATTRIBUTES.index_with { file.try(_1) }
    data_hash[:file_id] = file.id
    data_hash[:size] = number_to_human_size(file.size) rescue nil
    data_hash[:updated] = file.updated.to_i rescue nil
    data_hash[:user_name] = file.user.name if file.user.present?
    if file.sanitizer_state
      data_hash[:sanitizer_state] = file.sanitizer_state
      data_hash[:sanitizer_state_label] = file.label(:sanitizer_state)
    end
    data_hash
  end

  def file_link_tag(&block)
    data = { humanized_name: file.humanized_name, action: "ss--temp-file#selectFile" }
    link_to("#", class: "thumb", title: file.humanized_name, data: data, &block)
  end
end
