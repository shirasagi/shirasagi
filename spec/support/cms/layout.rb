def create_cms_layout(*parts)
  parts.flatten!
  options = parts.extract_options!
  html = []
  html << "<html><body><br><br><br>"
  html << parts.map { |m| '{{ part "/' + m.filename.sub(/\..*/, '') + '" }}' }.join("\n")
  html << "{{ yield }}"
  html << "</body></html>"
  create :cms_layout, options.merge(html: html.join)
end
