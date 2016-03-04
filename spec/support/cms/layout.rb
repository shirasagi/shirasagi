def create_cms_layout(parts)
  html = []
  html << "<html><body>"
  html << parts.map { |m| '{{ part "/' + m.filename.sub(/\..*/, '') + '" }}' }.join("\n")
  html << "{{ yield }}"
  html << "</body></html>"
  create :cms_layout, html: html.join
end
