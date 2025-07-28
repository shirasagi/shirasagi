class Cms::Agents::Parts::ClipboardCopyController < ApplicationController
  include Cms::PartFilter::View
  helper Event::EventHelper
  helper Cms::ArchiveHelper

  def index
    target = @cur_part.clipboard_copy_target.presence || 'url'
    if target == 'css_selector'
      selector = @cur_part.clipboard_copy_selector.presence || 'title'
    end

    # display_name が空の場合はパーツ名を使用
    display_name = @cur_part.clipboard_display_name.presence || @cur_part.name

    data = { target: target, selector: selector }
    html = view_context.button_tag(
      display_name, type: "button", name: "clipboard-copy", class: "btn-ss-clipboard-copy", data: data)
    render html: html
  end
end
