module Cms::Addon
  module RelatedPage
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :related_pages, class_name: "Cms::Page"
      permit_params related_page_ids: []
    end
  end

  module Role
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :cms_roles, class_name: "Cms::Role"
      permit_params cms_role_ids: []
    end
  end

  module NodeSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :view_route, type: String
      permit_params :view_route
    end
  end

  module Meta
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :keywords, type: SS::Extensions::Words
      field :description, type: String, metadata: { form: :text }
      field :summary_html, type: String, metadata: { form: :text }
      permit_params :keywords, :description, :summary_html

      before_save :set_keywords, if: ->{ @cur_site && @cur_site.auto_keywords_enabled? }
      before_save :set_description, if: ->{ @cur_site && @cur_site.auto_description_enabled? }
    end

    public
      def summary
        return summary_html if summary_html.present?
        return nil unless respond_to?(:html)
        html.gsub(/<("[^"]*"|'[^']*'|[^'">])*>/m, "").gsub(/\s+/, " ").truncate(120)
      end

      def meta_present?
        [keywords, description, summary_html].map(&:present?).any?
      end

    private
      def set_keywords
        return if keywords.present?

        keywords = []
        keywords << (parent ? parent.name : @cur_site.name)
        categories.each { |cate| keywords << cate.name }
        keywords += @cur_site.keywords.to_a
        self.keywords = keywords.uniq.join(", ")
      end

      def set_description
        return if description.present?
        return unless respond_to?(:html)
        self.description = ApplicationController.helpers.
          sanitize(html.to_s, tags: []).squish.truncate(60)
      end
  end

  module Html
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String, metadata: { form: :text }
      permit_params :html
    end
  end

  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String, metadata: { form: :text }
      field :markdown, type: String
      permit_params :html, :markdown

      validate :convert_markdown, if: -> { SS.config.cms.html_editor == "markdown" }
    end

    public
      def markdown2html
        ::Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(markdown)
      end

    private
      def convert_markdown
        self.html = markdown2html
      end
  end

  module Release
    extend ActiveSupport::Concern
    extend SS::Addon
  end

  module ReleasePlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :release_date, type: DateTime
      field :close_date, type: DateTime
      permit_params :release_date, :close_date

      validate :validate_release_date
      validate :validate_release_state
    end

    def validate_release_date
      self.released ||= release_date

      if close_date.present?
        if release_date.present? && release_date >= close_date
          errors.add :close_date, :greater_than, count: t(:release_date)
        end
      end
    end

    def validate_release_state
      return if errors.present?

      if state == "public"
        self.state = "ready" if release_date && release_date > Time.zone.now
        self.state = "closed" if close_date && close_date <= Time.zone.now
      end
    end
  end

  module Crumb
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :home_label, type: String
      permit_params :home_label
    end

    def home_label
      self[:home_label].presence || "HOME"
    end
  end

  module Tabs
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :conditions, type: SS::Extensions::Words
      field :limit, type: Integer, default: 8
      field :new_days, type: Integer, default: 1
      permit_params :conditions, :limit, :new_days

      before_validation :validate_conditions
    end

    public
      def limit
        value = self[:limit].to_i
        (value < 1 || 1000 < value) ? 100 : value
      end

      def new_days
        value = self[:new_days].to_i
        (value < 0 || 30 < value) ? 30 : value
      end

      def in_new_days?(date)
        date + new_days > Time.zone.now
      end

    private
      def validate_conditions
        self.conditions = conditions.map do |m|
          m.strip.sub(/^\w+:\/\/.*?\//, "").sub(/^\//, "").sub(/\/$/, "")
        end.compact.uniq
      end
  end

  module NodeList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    public
      def sort_options
        [
          [I18n.t('cms.options.sort.name'), 'name'],
          [I18n.t('cms.options.sort.filename'), 'filename'],
          [I18n.t('cms.options.sort.created'), 'created'],
          [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
          [I18n.t('cms.options.sort.order'), 'order'],
        ]
      end

      def sort_hash
        return { filename: 1 } if sort.blank?
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
  end

  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    public
      def sort_options
        [
          [I18n.t('cms.options.sort.name'), 'name'],
          [I18n.t('cms.options.sort.filename'), 'filename'],
          [I18n.t('cms.options.sort.created'), 'created'],
          [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
          [I18n.t('cms.options.sort.released_1'), 'released -1'],
          [I18n.t('cms.options.sort.order'), 'order'],
        ]
      end

      def sort_hash
        return { released: -1 } if sort.blank?
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
  end

  module Thumb
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      attr_accessor :in_thumb
      belongs_to_file :thumb
      permit_params :in_thumb
      validate :validate_thumb, if: ->{ in_thumb.present? }
    end

    private
      def validate_thumb
        file = relation_file(:thumb)
        errors.add :thumb_id, :thums_is_not_an_image unless file.image?
      end
  end

  module ParentCrumb
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :parent_crumb_urls, type: SS::Extensions::Lines
      permit_params :parent_crumb_urls
    end
  end

  module AdditionalInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :additional_info, type: Cms::Extensions::AdditionalInfo

      permit_params additional_info: [ :field, :value ]
    end
  end
end
