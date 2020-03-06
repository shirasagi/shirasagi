module Cms::Addon::List
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation

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

    def condition_hash(opts = {})
      cond = []
      cids = []
      cond_url = []

      if opts[:cur_main_path] && conditions.index('#{request_dir}')
        cur_dir = opts[:cur_main_path].sub(/\/[\w\-\.]*?$/, "").sub(/^\//, "")
        cond_url = conditions.map { |url| url.sub('#{request_dir}', cur_dir) }
      else
        if self.is_a?(Cms::Model::Part)
          if parent
            cond << { filename: /^#{::Regexp.escape(parent.filename)}\//, depth: depth }
            cids << parent.id
          else
            cond << { depth: depth }
          end
        else
          cond << { filename: /^#{::Regexp.escape(filename)}\//, depth: depth + 1 }
          cids << id
        end
        cond_url = conditions
      end

      cond_url.each do |url|
        # regex
        if url =~ /\/\*$/
          filename = url.sub(/\/\*$/, "")
          cond << { filename: /^#{::Regexp.escape(filename)}\// }
          next
        end

        node = Cms::Node.site(cur_site || site).filename(url).first rescue nil
        next unless node

        cond << { filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :category_ids.in => cids } if cids.present?
      cond << { :id => -1 } if cond.blank?

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
