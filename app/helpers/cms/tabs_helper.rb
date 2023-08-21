module Cms::TabsHelper
  include Cms::ListHelper

  def default_page_loop_html
    ih = []
    ih << '<article class="#{new}">'
    ih << '  <header>'
    ih << '    <time datetime="#{date.iso}">#{date.long}</time>'
    ih << '    <h3><a href="#{url}">#{index_name}</a></h3>'
    ih << '  </header>'
    ih << '</article>'
    ih.join("\n").freeze
  end
end
