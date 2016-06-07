module Cms::Addon::List
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation
    include SS::TemplateVariable

    attr_accessor :cur_date

    included do
      field :conditions, type: SS::Extensions::Words
      field :sort, type: String
      field :limit, type: Integer, default: 20
      field :loop_html, type: String
      field :upper_html, type: String
      field :lower_html, type: String
      field :new_days, type: Integer, default: 1
      permit_params :conditions, :sort, :limit, :loop_html, :upper_html, :lower_html, :new_days

      before_validation :validate_conditions

      template_variable_handler(:name, :template_variable_handler_name)
      template_variable_handler(:url, :template_variable_handler_name)
      template_variable_handler(:summary, :template_variable_handler_name)
      template_variable_handler(:index_name, :template_variable_handler_index_name)
      template_variable_handler(:class, :template_variable_handler_class)
      template_variable_handler(:new, :template_variable_handler_new)
      template_variable_handler(:date, :template_variable_handler_date)
      template_variable_handler('date.default') { |name, item| template_variable_handler_date(name, item, :default) }
      template_variable_handler('date.iso') { |name, item| template_variable_handler_date(name, item, :iso) }
      template_variable_handler('date.long') { |name, item| template_variable_handler_date(name, item, :long) }
      template_variable_handler('date.short') { |name, item| template_variable_handler_date(name, item, :short) }
      template_variable_handler(:time, :template_variable_handler_time)
      template_variable_handler('time.default') { |name, item| template_variable_handler_time(name, item, :default) }
      template_variable_handler('time.iso') { |name, item| template_variable_handler_time(name, item, :iso) }
      template_variable_handler('time.long') { |name, item| template_variable_handler_time(name, item, :long) }
      template_variable_handler('time.short') { |name, item| template_variable_handler_time(name, item, :short) }
      template_variable_handler('img.src') { |name, item| template_variable_handler_img_src(name, item) }
      template_variable_handler(:group, :template_variable_handler_group)
      template_variable_handler(:groups, :template_variable_handler_groups)
    end

    def sort_options
      []
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

      if opts[:cur_path] && conditions.index('#{request_dir}')
        cur_dir = opts[:cur_path].sub(/\/[\w\-\.]*?$/, "").sub(/^\//, "")
        cond_url = conditions.map {|url| url.sub('#{request_dir}', cur_dir)}
      else
        if self.is_a?(Cms::Model::Part)
          if parent
            cond << { filename: /^#{parent.filename}\//, depth: depth }
            cids << parent.id
          else
            cond << { depth: depth }
          end
        else
          cond << { filename: /^#{filename}\//, depth: depth + 1 }
          cids << id
        end
        cond_url = conditions
      end

      cond_url.each do |url|
        # regex
        if url =~ /\/\*$/
          filename = url.sub(/\/\*$/, "")
          cond << { filename: /^#{filename}\// }
          next
        end

        node = Cms::Node.filename(url).first
        next unless node

        cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
        cids << node.id
      end
      cond << { :category_ids.in => cids } if cids.present?
      cond << { :id => -1 } if cond.blank?

      { '$or' => cond }
    end

    def render_loop_html(item, opts = {})
      item = item.becomes_with_route rescue item
      render_template(opts[:html] || loop_html, item)
    end

    private
      def validate_conditions
        self.conditions = conditions.map do |m|
          m.strip.sub(/^\w+:\/\/.*?\//, "").sub(/^\//, "").sub(/\/$/, "")
        end.compact.uniq
      end

      def template_variable_handler_name(name, item)
        ERB::Util.html_escape item.send(name)
      end

      def template_variable_handler_index_name(name, item)
        ERB::Util.html_escape item.name_for_index
      end

      def template_variable_handler_class(name, item)
        item.basename.sub(/\..*/, "").dasherize
      end

      def template_variable_handler_new(name, item)
        respond_to?(:in_new_days?) && in_new_days?(item.date) ? "new" : nil
      end

      def template_variable_handler_date(name, item, format = nil)
        if format.nil?
          I18n.l item.date.to_date
        else
          I18n.l item.date.to_date, format: format.to_sym
        end
      end

      def template_variable_handler_time(name, item, format = nil)
        if format.nil?
          I18n.l item.date
        else
          I18n.l item.date, format: format.to_sym
        end
      end

      def template_variable_handler_img_src(name, item)
        dummy_source = ERB::Util.html_escape("/assets/img/dummy.png")

        return dummy_source unless item.respond_to?(:html)
        return dummy_source unless item.html =~ /\<\s*?img\s+[^>]*\/?>/i

        img_tag = $&
        return dummy_source unless img_tag =~ /src\s*=\s*(['"]?[^'"]+['"]?)/

        img_source = $1
        img_source = img_source[1..-1] if img_source.start_with?("'") || img_source.start_with?('"')
        img_source = img_source[0..-2] if img_source.end_with?("'") || img_source.end_with?('"')
        img_source = img_source.strip
        if img_source.start_with?('.')
          #img_source = File.dirname(item.url) + '/' + img_source
        end
        img_source
      end

      def template_variable_handler_group(name, item)
        group = item.groups.first
        group ? group.name.split(/\//).pop : ""
      end

      def template_variable_handler_groups(name, item)
        item.groups.map { |g| g.name.split(/\//).pop }.join(", ")
      end
  end
end
