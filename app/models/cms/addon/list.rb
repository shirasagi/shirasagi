module Cms::Addon::List
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation

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
    end

    public
      def sort_options
        []
      end

      def sort_hash
        {}
      end

      def limit
        value = self[:limit].to_i
        (value < 1 || 100 < value) ? 100 : value
      end

      def new_days
        value = self[:new_days].to_i
        (value < 0 || 30 < value) ? 30 : value
      end

      def in_new_days?(date)
        date + new_days > (@cur_date || Time.now)
      end

      def condition_hash
        cond = []
        cids = []

        if self.is_a?(Cms::Part::Model)
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

        conditions.each do |url|
          node = Cms::Node.filename(url).first
          next unless node
          cond << { filename: /^#{node.filename}\//, depth: node.depth + 1 }
          cids << node.id
        end
        cond << { :category_ids.in => cids } if cids.present?

        { '$or' => cond }
      end

      def render_loop_html(item, opts = {})
        (opts[:html] || loop_html).gsub(/\#\{(.*?)\}/) do |m|
          str = template_variable_get(item, $1) rescue false
          str == false ? m : str
        end
      end

      def template_variable_get(item, name)
        if name =~ /^(name|url|summary)$/
          ERB::Util.html_escape item.send(name)
        elsif name == "class"
          item.basename.sub(/\..*/, "").dasherize
        elsif name == "new"
          respond_to?(:in_new_days?) && in_new_days?(item.date) ? "new" : nil
        elsif name == "date"
          I18n.l item.date.to_date
        elsif name =~ /^date\.(\w+)$/
          I18n.l item.date.to_date, format: $1.to_sym
        elsif name == "time"
          I18n.l item.date
        elsif name =~ /^time\.(\w+)$/
          I18n.l item.date, format: $1.to_sym
        else
          false
        end
      end

    private
      def validate_conditions
        self.conditions = conditions.map do |m|
          m.strip.sub(/^\w+:\/\/.*?\//, "").sub(/^\//, "").sub(/\/$/, "")
        end.compact.uniq
      end
  end
end
