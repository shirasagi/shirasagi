class Rss::Page
  include Cms::Model::Page
  include Rss::Addon::Page::Body
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Cms::Addon::RelatedPage
  include Cms::Addon::Release
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "article_pages"

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "rss/page") }

  public
    def url
      rss_link
    end

    def full_url
      rss_link
    end

    def json_path
      nil
    end

    def json_url
      nil
    end

    def self.limit_docs(site, node, max)
      return if max.blank? || max <= 0

      criteria = Rss::Page.site(site).node(node)
      count = criteria.count
      if count > max
        limit = count - max
        criteria.order(released: 1, _id: 1).limit(limit).each do |item|
          item.destroy
          yield item if block_given?
        end
      end
    end

    def serve_static_file?
      false
    end

  private
    def validate_filename
      # (@basename && @basename.blank?) ? nil : super
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end
end
