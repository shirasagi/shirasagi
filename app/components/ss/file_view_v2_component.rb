#frozen_string_literal: true

class SS::FileViewV2Component < SS::FileViewComponent
  attr_accessor :animated

  def file_view_tag_css_class
    [ "file-view", animated ]
  end

  def file_link_tag(&block)
    data = { action: "ss--file-select-box#openFile" }
    link_to(file.url, class: "thumb", target: "_blank", rel: "noopener", data: data, &block)
  end

  def default_attach_action
    button_tag(
      t("sns.file_attach"), type: :button, name: 'file_attach', class: 'btn',
      data: { action: "ss--file-select-box#attachFile" })
  end

  def default_image_paste_action
    button_tag(
      t("sns.image_paste"), type: :button, name: 'image_paste', class: 'btn',
      data: { action: "ss--file-select-box#pasteImage" })
  end

  def default_thumb_paste_action
    button_tag(
      t("sns.thumb_paste"), type: :button, name: 'thumb_paste', class: 'btn',
      data: { action: "ss--file-select-box#pasteThumbnail" })
  end

  def default_delete_action
    button_tag(
      t("ss.buttons.delete"), type: :button, name: 'delete', class: 'btn',
      data: { action: "ss--file-select-box#deleteFile" })
  end

  def default_copy_url_action
    button_tag(
      t("ss.buttons.copy_url"), type: :button, name: 'copy_url', class: 'btn',
      data: { action: "ss--file-select-box#copyUrl" })
  end
end
