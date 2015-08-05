module SS::Document
  extend ActiveSupport::Concern
  extend SS::Translation
  include Mongoid::Document
  include SS::Fields::Sequencer
  include SS::Fields::Normalizer

  attr_accessor :in_updated

  included do
    class_variable_set(:@@_permit_params, [])
    class_variable_set(:@@_text_index_fields, [])

    field :created, type: DateTime, default: -> { Time.zone.now }
    field :updated, type: DateTime, default: -> { created }
    field :text_index, type: String

    validate :validate_updated, if: -> { in_updated.present? }
    before_save :set_db_changes
    before_save :set_updated
    before_save :set_text_index

    scope :keyword_in, ->(words, *fields) {
      words = words.split(/[\s　]+/).uniq.compact.map { |w| /#{Regexp.escape(w)}/i } if words.is_a?(String)
      words = words[0..4]
      cond  = words.map do |word|
        { "$or" => fields.map { |field| { field => word } } }
      end
      where("$and" => cond)
    }

    scope :search_text, ->(words) {
      words = words.split(/[\s　]+/).uniq.compact.map { |w| /#{Regexp.escape(w)}/i } if words.is_a?(String)
      if self.class_variable_get(:@@_text_index_fields).present?
        all_in text_index: words
      else
        all_in name: words
      end
    }
  end

  module ClassMethods
    def t(*args)
      human_attribute_name *args
    end

    def tt(key, html_wrap = true)
      modelnames = ancestors.select { |x| x.respond_to?(:model_name) }
      msg = ""
      modelnames.each do |modelname|
        msg = I18n.t("tooltip.#{modelname.model_name.i18n_key}.#{key}", default: "")
        break if msg.present?
      end
      return msg if msg.blank? || !html_wrap
      msg = [msg] if msg.class.to_s == "String"
      list = msg.map {|d| "<li>" + d.to_s.gsub(/\r\n|\n/, "<br />") + "<br /></li>"}

      h  = []
      h << %(<div class="tooltip">?)
      h << %(<ul>)
      h << list
      h << %(</ul>)
      h << %(</div>)
      h.join("\n").html_safe
    end

    def seqid(name = :id)
      sequence_field name

      if name == :id
        replace_field "_id", Integer
      else
        field name, type: Integer
      end
    end

    def embeds_ids(name, opts = {})
      store = opts[:store_as] || "#{name.to_s.singularize}_ids"
      field store, type: SS::Extensions::ObjectIds, default: [],
            overwrite: true, metadata: { elem_class: opts[:class_name] }
      define_method(name) { opts[:class_name].constantize.where :_id.in => send(store) }
    end

    def permitted_fields
      class_variable_get(:@@_permit_params)
    end

    def permit_params(*fields)
      params = class_variable_get(:@@_permit_params)
      class_variable_set(:@@_permit_params, params + fields)
    end

    def addon(path)
      include path.sub("/", "/addon/").camelize.constantize
    end

    def addons
      #return @addons if @addons
      @addons = lookup_addons.reverse.map { |m| m.addon_name }
    end

    def lookup_addons
      ancestors.select { |x| x.respond_to?(:addon_name) }
    end

    def text_index(*args)
      fields = class_variable_get(:@@_text_index_fields)

      if args[0].is_a?(Hash)
        opts = args[0]
        if opts[:only]
          fields = opts[:only]
        elsif opts[:except]
          fields.reject! { |m| opts[:except].include?(m) }
        end
      else
        fields += args
      end

      class_variable_set(:@@_text_index_fields, fields)
    end

    # Mongoid では find_in_batches が存在しない。
    # find_in_batches のエミュレーションを提供する。
    #
    # ActiveRecord の find_in_batches と異なる点がある。
    #
    # ActiveRecord の find_in_batches では、start オプションを取るが、本メソッドは offset オプションを取る。
    # start オプションは主キーを取るが、offset オプションは読み飛ばすレコード数を取る。
    #
    # ActiveRecord の find_in_batches では、order_by が無効になるが、本メソッドでは order_by が有効である。
    #
    # @return [Enumerator<Array<self.class>>]
    def find_in_batches(options = {})
      unless block_given?
        return to_enum(:find_in_batches, options)
      end

      batch_size = options[:batch_size] || 1000
      offset = options[:offset] || 0
      records = self.limit(batch_size).skip(offset).to_a
      while records.any?
        records_size = records.size
        with_scope(Mongoid::Criteria.new(self)) do
          yield records
        end
        break if records_size < batch_size
        offset += batch_size
        records = self.limit(batch_size).skip(offset).to_a
      end
    end

    # Mongoid では find_each が存在しない。
    # find_each のエミュレーションを提供する。
    #
    # ActiveRecord の find_in_batches と異なる点がある。
    #
    # ActiveRecord の find_in_batches では、start オプションを取るが、本メソッドは offset オプションを取る。
    # start オプションは主キーを取るが、offset オプションは読み飛ばすレコード数を取る。
    #
    # ActiveRecord の find_in_batches では、order_by が無効になるが、本メソッドでは order_by が有効である。
    #
    # @return [Enumerator<self.class>]
    def find_each(options = {})
      unless block_given?
        return to_enum(:find_each, options)
      end

      find_in_batches(options) do |records|
        records.each do |record|
          yield record
        end
      end
    end
  end

  public
    def t(name)
      self.class.t name
    end

    def tt(key, html_wrap = true)
      self.class.tt key, html_wrap
    end

    def label(name)
      opts  = send("#{name}_options")
      opts += send("#{name}_private_options") if respond_to?("#{name}_private_options")

      if send(name).blank?
        opts.each {|m| return m[0] if m[1].blank? }
      else
        opts.each {|m| return m[0] if m[1].to_s == send(name).to_s }
      end
      nil
    end

    def validate_updated
      errors.add :base, :invalid_updated if in_updated.to_s != updated.to_s
    end

  private
    def set_db_changes
      @db_changes = changes
    end

    def set_updated
      return true if !changed?
      self.updated = Time.zone.now
    end

    def set_text_index
      fields = self.class.class_variable_get(:@@_text_index_fields)
      return if fields.blank?

      texts = []
      fields.map do |name|
        text = send(name)
        next if text.blank?
        text.gsub!(/<("[^"]*"|'[^']*'|[^'">])*>/, " ") if name =~ /html$/
        text.gsub!(/\s+/, " ")
        texts << text
      end
      self.text_index = texts.join(" ")
    end
end
