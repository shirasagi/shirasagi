class Cms::Agents::Parts::ClipboardCopyController < ApplicationController
  include Cms::PartFilter::View
  helper Event::EventHelper
  helper Cms::ArchiveHelper

  def index
    target = @cur_part.clipboard_copy_target.presence || 'url'
    if target == 'css_selector'
      selector = @cur_part.clipboard_copy_selector.presence || 'title'
    end

    data = { target: target, selector: selector }
    html = view_context.button_tag(
      @cur_part.name, type: "button", name: "clipboard-copy", class: "btn-ss-clipboard-copy", data: data)
    render html: html
  end
end
