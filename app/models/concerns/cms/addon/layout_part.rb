module Cms::Addon
  module LayoutPart
    extend ActiveSupport::Concern
    extend SS::Addon

    def parse_part_paths
      parts = {}
      html.to_s.scan(/(<\/|\{\{) part "(.*?)" (\/>|\}\})/) do
        path = "#{$2}.part.html"
        path = path[0] == "/" ? path.sub(/^\//, "") : dirname(path)
        parts[path] = nil
      end
      parts
    end

    def parse_parts
      parts = parse_part_paths
      paths = parts.keys
      entries = Cms::Part.site(site).and_public.any_in(filename: paths).entries

      paths.each do |path|
        parts[path] = entries.find { |c| c.filename == path }
      end
      parts
    end
  end
end
