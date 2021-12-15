module SS::Document
  extend ActiveSupport::Concern
  extend SS::Translation
  include Mongoid::Document
  include SS::Scope::Base
  include SS::PermitParams
  include SS::Fields::Sequencer
  include SS::Fields::Normalizer

  attr_accessor :in_updated

  included do
    field :created, type: DateTime, default: -> { Time.zone.now }
    field :updated, type: DateTime, default: -> { created }
    field :deleted, type: DateTime
    field :text_index, type: String

    validate :validate_updated, if: -> { in_updated.present? }
    validates :created, datetime: true
    validates :updated, datetime: true
    validates :deleted, datetime: true
    before_save :set_db_changes
    before_save :set_updated
    before_save :set_text_index
  end

  module ClassMethods
    def default_client?
      persistence_context.send(:client_name) == :default
    end

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
      list = msg.map { |d| "<li>" + d.to_s.gsub(/\r\n|\n/, "<br />") + "<br /></li>" }

      h = []
      h << %(<div class="tooltip">?)
      h << %(<ul class="tooltip-content">)
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
            overwrite: true, metadata: { elem_class: opts[:class_name] }.merge(opts[:metadata] || {})
      define_method(name) { opts[:class_name].constantize.where("$and" => [{ :_id.in => send(store) }]) }
      define_method("ordered_#{name}") do
        items = send(name).to_a
        send(store).map { |id| items.find { |item| item.id == id } }
      end
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

    def total_bsonsize
      return 0 unless Mongoid::Criteria.new(self).exists?
      map = %(function(){ emit(1, Object.bsonsize(this)); })
      reduce = %(function(k, v){ if (0 == v.length) return 0; return Array.sum(v); })
      data = map_reduce(map, reduce).out(inline: 1).first.try(:[], :value).to_i || 0
    end

    def labels
      fields.collect do |field|
        [field[0], t(field[0])]
      end.to_h
    end
  end

  def assign_attributes_safe(attr)
    self.attributes = attr.slice(*self.class.fields.keys)
    self
  end

  def t(name, opts = {})
    self.class.t name, opts
  end

  def tt(key, html_wrap = true)
    self.class.tt key, html_wrap
  end

  def addons(addon_type = nil)
    if addon_type
      self.class.addons.select { |m| m.type == addon_type }
    else
      self.class.addons.select { |m| m.type.nil? }
    end
  end

  def value_setting_for(name, options = {})
    return unless respond_to?("#{name}_options")

    opts  = send("#{name}_options")
    opts += send("#{name}_private_options") if respond_to?("#{name}_private_options")
    value = options.key?(:value) ? options[:value] : send(name)

    if value.blank?
      opts.each { |m| return m if m[1].blank? }
    else
      opts.each { |m| return m if m[1].to_s == value.to_s }
    end
    nil
  end

  def label(name, options = {})
    value_setting_for(name, options).try { |setting| setting[0] }
  end

  def validate_updated
    errors.add :base, :invalid_updated if in_updated.to_s != updated.to_s
  end

  def record_timestamps
    @record_timestamps = true if @record_timestamps.nil?
    @record_timestamps
  end

  def record_timestamps=(val)
    @record_timestamps = val
  end

  def becomes_with(klass)
    item = klass.new
    item.instance_variable_set(:@new_record, nil) unless new_record?
    instance_variables.each { |k| item.instance_variable_set k, instance_variable_get(k) }
    # clear changes
    item.move_changes
    item
  end

  private

  def set_db_changes
    @db_changes = changes
  end

  def set_updated
    return true if !changed?
    return true if !record_timestamps
    self.updated = updated ? Time.zone.now : created
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
