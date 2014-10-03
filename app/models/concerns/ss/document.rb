# coding: utf-8
module SS::Document
  extend ActiveSupport::Concern
  extend SS::Translation
  include Mongoid::Document
  include SS::Fields::Sequencer

  included do
    class_variable_set(:@@_permit_params, [])
    field :created, type: DateTime, default: -> { Time.now }
    field :updated, type: DateTime, default: -> { Time.now }
    before_save :set_db_changes
    before_save :set_updated
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
      list = msg.map {|d| "<li>" + d.gsub(/\r\n|\n/, "<br />") + "</li>"}

      h  = []
      h << %(<div class="tooltip">?)
      h << %(<ul>)
      h << list
      h << %(</ul>)
      h << %(</div>)
      h.join("\n").html_safe
    end

    def seqid(name = :id, opts = {})
      sequence_field name

      if name == :id
        replace_field "_id", Integer
        use_id_field if opts[:field] == true
      end
      field name, type: Integer
    end

    def use_id_field(name)
      aliased_fields.delete(name.to_s)
      define_method(name) { @attributes[name.to_s] }
      define_method("#{name}=") {|val| @attributes[name.to_s] = val }
    end

    def embeds_ids(name, opts = {})
      store = opts[:store_as] || "#{name.to_s.singularize}_ids"
      field store, type: SS::Extensions::ObjectIds, default: []
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
      @addons = lookup_addons.sort {|a, b| a.order <=> b.order }.map {|m| m.addon_name }
    end

    def lookup_addons
      ancestors.select { |x| x.respond_to?(:addon_name) }
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

  private
    def set_db_changes
      @db_changes = changes
    end

    def set_updated
      return true if !changed?
      self.updated = Time.now
    end
end
