class Cms::LineUtils
  class << self
    def flex_carousel_template(title, items)
      items = [items] if !items.is_a?(Array)

      contents = items.map do |item|
        opts = OpenStruct.new
        yield(item, opts)

        image = opts[:image]
        image_url = opts[:image_url]
        name = opts[:name].to_s
        text = opts[:text].to_s
        action = opts[:action]
        bookmark = opts[:bookmark]

        content = { type: "bubble", size: "kilo" }

        if image
          content[:hero] = {
            type: "image",
            url: image.full_url,
            size: "full",
            aspectRatio: "20:13",
            aspectMode: "cover"
          }
        elsif image_url
          content[:hero] = {
            type: "image",
            url: image_url,
            size: "full",
            aspectRatio: "20:13",
            aspectMode: "cover"
          }
        end

        content[:body] = {
          type: "box",
          layout: "vertical",
          contents: []
        }

        # name
        content[:body][:contents] << {
          type: "text",
          text: name,
          wrap: true,
          weight: "bold",
          margin: "none"
        }

        # bookmark
        if bookmark
          icon_url = ::File.join(item.site.full_url, "/assets/img/line/bookmark.png") rescue nil
          bookmark_contents = []
          bookmark_contents << {
            type: "text",
            text: "お気に入り",
            wrap: true,
            size: "sm",
            weight: "bold",
            margin: "sm",
            flex: 0
          }
          if icon_url.present?
            bookmark_contents << {
              type: "icon",
              size: "10px",
              url: icon_url
            }
          end
          content[:body][:contents] << {
            type: "box",
            layout: "baseline",
            margin: "md",
            contents: bookmark_contents
          }
        end

        # text
        text.split("\n").each_with_index do |line, idx|
          content[:body][:contents] << {
            type: "text",
            text: line,
            wrap: true,
            size: "sm",
            margin: (idx == 0) ? "md" : "none"
          }
        end

        # action
        if action
          content[:footer] = {
            type: "box",
            layout: "vertical",
            contents: [{
              type: "button",
              action: action,
              style: "secondary",
              margin: "none"
            }]
          }
          content[:styles] = { footer: { separator: true } }
        end

        content
      end

      {
        type: "flex",
        altText: title,
        contents: {
          type: "carousel",
          contents: contents
        }
      }
    end
  end
end
