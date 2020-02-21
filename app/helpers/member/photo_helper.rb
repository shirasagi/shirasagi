module Member::PhotoHelper
  include Cms::ListHelper

  def default_page_loop_html
    ih = []
    ih << '<div class="photo">'
    ih << '  <a href="#{url}">'
    ih << '     <img src="#{thumb.src}" alt="#{name}" class="thumb">'
    ih << '     <span class="title">#{name}</span>'
    ih << '  </a>'
    ih << '</div>'
    ih.join("\n").freeze
  end
end
