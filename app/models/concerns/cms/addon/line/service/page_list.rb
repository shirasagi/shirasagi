module Cms::Addon
  module Line::Service::PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model
    include SS::Relation::File
    include Fs::FilePreviewable

    included do
      self.default_limit = 10
      belongs_to_file :no_image, static_state: "public"
      validates :limit, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
    end

    def state
      "public"
    end

    def file_previewable?(file, user:, member:)
      true
    end

    def interpret_default_location(default_site, &block)
    end

    def page_text(page, assigns = {})
      assigns["page"] = page
      assigns.stringify_keys!
      template = ::Cms.parse_liquid(loop_liquid, { cur_site: site })
      template.render(assigns).html_safe
    end

    def page_image_url(page)
      image_url = nil
      image_url = no_image.full_url if no_image
      if page.thumb
        image_url = page.thumb.full_url
      else
        html = page.form ? page.column_values.map(&:to_html).join("\n") : page.html
        src = SS::Html.extract_img_src(html.to_s, site.full_root_url)
        image_url = ::File.join(site.full_root_url, src) if src.present? && src.start_with?('/')
      end
      image_url
    end
  end
end
