module Cms::Addon::List
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation

    WELL_KONWN_CONDITION_HASH_OPTIONS = %i[site default_location request_dir category bind].freeze
    attr_accessor :cur_date

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

    def interpret_conditions(options, &block)
      default_site = options[:site] || @cur_site || self.site
      default_location = options.fetch(:default_location, :default)
      request_dir = options.fetch(:request_dir, nil)
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
          next unless request_dir

          # #{request_dir} indicates "special default location".
          # usually default location is a current node (or current part's parent if part is given).
          # if #{request_dir} is specified, default location is changed to cur_main_path.
          cur_dir ||= request_dir.sub(/\/[\w\-\.]*?$/, "").sub(/^\//, "")
          url = url.sub('#{request_dir}', cur_dir)
          interprets_default_location = true
        end

        yield site, url
      end

      if default_location == :default && !interprets_default_location
        interpret_default_location(default_site, &block)
      elsif default_location == :only_blank && conditions.blank?
        interpret_default_location(default_site, &block)
      end
    end

    def condition_hash(options = {})
      category_key = options.fetch(:category, :category_ids)
      bind = options.fetch(:bind, :children)
      conditions = []

      pending_nodes = []
      pending_filenames = []
      interpret_conditions(options) do |site, content_or_path|
        if content_or_path.is_a?(Cms::Content)
          pending_nodes << [ site, content_or_path, bind, category_key ]
        elsif content_or_path == :root_contents
          conditions << { site_id: site.id, filename: /^[^\/]+$/, depth: 1 }
          next
        elsif content_or_path.end_with?("*")
          # wildcard
          filename = content_or_path[0..-2]
          filename = filename[0..-2] if filename.end_with?("/")
          pending_filenames << [ site, filename, :descendants, nil ]
          next
        else
          pending_filenames << [ site, content_or_path, bind, category_key ]
        end
      end

      pending_nodes += retrieve_nodes(pending_filenames) if pending_filenames.present?

      category_ids = []
      pending_nodes.each do |site, node, bind, category_key|
        if bind == :children
          conditions << { site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1 }
        elsif bind == :descendants
          conditions << { site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\// }
        end
        category_ids << [ site.id, node.id ] if category_key
      end
      conditions += bind_to_category(category_key, category_ids) if category_key

      return { "$and" => [{ id: -1 }] } if conditions.blank?

      { '$or' => conditions }
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

    def interpret_default_location(default_site, &block)
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

    def retrieve_nodes(pending_filenames)
      return [] if pending_filenames.blank?

      all_nodes = begin
        nodes_conditions = pending_filenames.map do |site, filename, _bind, _category_key|
          { site_id: site.id, filename: filename.start_with?("/") ? filename[1..-1] : filename }
        end
        Cms::Node.unscoped.where("$or" => nodes_conditions).to_a
      end

      pending_filenames.map do |site, filename, bind, category_key|
        node = all_nodes.find { |node| node.site_id == site.id && node.filename == filename }
        next unless node

        [ site, node, bind, category_key ]
      end.compact
    end

    def bind_to_category(category_key, category_ids)
      cond = []

      return cond if category_ids.blank?

      if category_ids.length == 1
        cond << { site_id: category_ids.first[0], category_key => category_ids.first[1] }
        return cond
      end

      category_ids.group_by { |site_id, _node_id| site_id }.each do |site_id, ids|
        node_ids = ids.map { |_site_id, node_id| node_id }
        if node_ids.length == 1
          cond << { site_id: site_id, category_key => node_ids.first }
        else
          cond << { site_id: site_id, category_key => { "$in" => node_ids } }
        end
      end

      cond
    end
  end
end
