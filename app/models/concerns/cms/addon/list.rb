module Cms::Addon::List
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_date
    attr_accessor :cur_main_path

    included do
      cattr_accessor(:use_new_days, instance_accessor: false) { true }
      cattr_accessor(:use_liquid, instance_accessor: false) { true }

      field :conditions, type: SS::Extensions::Words
      field :sort, type: String
      field :limit, type: Integer, default: 20
      field :loop_html, type: String
      field :upper_html, type: String
      field :lower_html, type: String
      field :new_days, type: Integer, default: 1
      field :loop_format, type: String
      field :loop_liquid, type: String
      field :no_items_display_state, type: String
      field :substitute_html, type: String

      belongs_to :loop_setting, class_name: 'Cms::LoopSetting'

      permit_params :conditions, :sort, :limit, :loop_html, :loop_setting_id, :upper_html, :lower_html, :new_days
      permit_params :no_items_display_state, :substitute_html, :loop_format, :loop_liquid

      before_validation :validate_conditions

      validates :no_items_display_state, inclusion: { in: %w(show hide), allow_blank: true }
      validates :loop_format, inclusion: { in: %w(shirasagi liquid), allow_blank: true }
      validates :loop_liquid, liquid_format: true, if: ->{ loop_format_liquid? }
    end

    def sort_options
      []
    end

    def no_items_display_state_options
      %w(show hide).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
    end

    def loop_format_options
      %w(shirasagi liquid).map do |v|
        [ I18n.t("cms.options.loop_format.#{v}"), v ]
      end
    end

    def loop_format_liquid?
      loop_format == "liquid"
    end

    def loop_format_shirasagi?
      !loop_format_liquid?
    end

    def sort_hash
      {}
    end

    def limit
      value = self[:limit].to_i
      (value < 1 || 1000 < value) ? 100 : value
    end

    def new_days
      value = self[:new_days].to_i
      (value < 0 || 30 < value) ? 30 : value
    end

    def in_new_days?(date)
      date + new_days > (@cur_date || Time.zone.now)
    end

    def interpret_conditions(default_site, &block)
      cur_dir = nil
      interprets_default_location = false

      conditions.each do |url_with_host|
        host, url = url_with_host.split(":", 2)
        host, url = url, host if url.blank?

        if host.present?
          site = Cms::Site.where(host: host).first
          next if site.blank? || !(site.parent.id == default_site.id || site.partner_site_ids.include?(default_site.id))
        end
        site ||= default_site

        if url.include?('#{request_dir}')
          next if cur_main_path.blank?

          # #{request_dir} indicates "special default location".
          # usually default location is a current node (or current part's parent if part is given).
          # if #{request_dir} is specified, default location is changed to cur_main_path.
          cur_dir ||= cur_main_path.sub(/\/[\w\-\.]*?$/, "").sub(/^\//, "")
          url = url.sub('#{request_dir}', cur_dir)
          interprets_default_location = true
        end

        yield site, url
      end

      unless interprets_default_location
        if self.is_a?(Cms::Model::Part)
          if parent
            yield parent.site, parent
          else
            yield default_site, :root_contents
          end
        else
          yield self.site, self
        end
      end
    end

    def condition_hash(options = {})
      default_site = options[:site] || @cur_site || self.site
      cond = []
      category_ids = []

      interpret_conditions(default_site) do |site, content_or_path|
        if content_or_path.is_a?(Cms::Content)
          node = content_or_path
        elsif content_or_path == :root_contents
          cond << { site_id: site.id, filename: /^[^\/]+$/, depth: 1 }
          next
        elsif content_or_path.end_with?("*")
          # wildcard
          cond << { site_id: site.id, filename: /^#{::Regexp.escape(content_or_path[0..-2])}/ }
          next
        else
          node = Cms::Node.site(site).filename(content_or_path).first rescue nil
          next unless node
        end

        cond << { site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1 }
        category_ids << [ site.id, node.id ]
      end

      if category_ids.present?
        if category_ids.length == 1
          cond << { site_id: category_ids.first[0], category_ids: category_ids.first[1] }
        else
          category_ids.group_by { |site_id, _node_id| site_id }.each do |site_id, ids|
            node_ids = ids.map { |_site_id, node_id| node_id }
            if node_ids.length == 1
              cond << { site_id: site_id, category_ids: node_ids.first }
            else
              cond << { site_id: site_id, :category_ids.in => node_ids }
            end
          end
        end
      end

      return { "$and" => [{ id: -1 }] } if cond.blank?

      { '$or' => cond }
    end

    def render_loop_html(item, opts = {})
      item = item.becomes_with_route rescue item
      item.render_template(opts[:html] || loop_html, self)
    end

    private

    def validate_conditions
      self.conditions = conditions.map do |m|
        m.strip.sub(/^\w+:\/\/.*?\//, "").sub(/^\//, "").sub(/\/$/, "")
      end.compact.uniq
    end
  end
end
