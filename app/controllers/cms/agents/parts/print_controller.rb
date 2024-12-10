class Cms::Agents::Parts::PrintController < ApplicationController
  include Cms::PartFilter::View
  helper Event::EventHelper
  helper Cms::ArchiveHelper
  helper Cms::ListHelper

  def index
    # display_name が空の場合はパーツ名を使用
    print_parts_display_name = @cur_part.print_display_name.presence || @cur_part.name

    render html: view_context.button_tag(
      print_parts_display_name, # 変数を使用
      type: "button",
      name: "print",
      class: "btn-ss-print"
    )
  end
end
