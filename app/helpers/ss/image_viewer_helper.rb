module SS::ImageViewerHelper
  def render_image_viewer(selector, tile_sources, opts = {})
    image_viewer_options = opts[:viewer] || {}
    image_viewer_options.reverse_merge!(SS::Config.image_viewer.options)
    image_viewer_options[:id] = selector.sub(/\A#/, '')
    image_viewer_options[:tileSources] =
      case tile_sources
      when Array
        tile_sources.collect do |tile_source|
          JSON.parse(tile_source) rescue tile_source
        end
      when Hash
        tile_sources
      when String
        JSON.parse(tile_sources) rescue tile_sources
      else
        tile_sources
      end
    s = []

    controller.javascript "/assets/js/openseadragon/openseadragon.min.js"

    s << "var options = #{image_viewer_options.to_json};"
    s << 'var viewer = SS_ImageViewer.render(options);'

    jquery { s.join("\n").html_safe }
  end
end
