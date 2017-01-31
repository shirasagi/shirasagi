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

      if opts[:cur_main_path] && conditions.index('#{request_dir}')
        cur_dir = opts[:cur_main_path].sub(/\/[\w\-\.]*?$/, "").sub(/^\//, "")
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
