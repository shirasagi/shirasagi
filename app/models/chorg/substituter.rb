module Chorg::Substituter
  # @private
  class BaseSubstituter
    include Comparable

    attr_reader :from_value, :to_value, :key, :group_ids

    def <=>(other)
      ret = from_value.class.to_s <=> other.from_value.class.to_s
      ret = other.from_value.length <=> from_value.length if ret == 0 && from_value.respond_to?(:length)
      ret = other.from_value <=> from_value if ret == 0
      ret = to_value.class.to_s <=> other.to_value.class.to_s if ret == 0
      ret = other.to_value.length <=> to_value.length if ret == 0 && from_value.respond_to?(:length)
      ret = other.to_value <=> to_value if ret == 0
      ret
    end
  end

  # @private
  class IdSubstituter < BaseSubstituter
    def initialize(from_value, to_value, key = nil, group_ids = nil)
      @from_value = from_value
      @to_value = to_value
      @first_to_value = @to_value.is_a?(Array) ? @to_value.first : @to_value
      @key = key
      @group_ids = group_ids
    end

    def call(key, value, group_id)
      if value.is_a?(Integer)
        value == @from_value ? @first_to_value : value
      elsif value.is_a?(Enumerable)
        value.map { |e| e == @from_value ? @to_value : e }.flatten.uniq
      else
        value
      end
    end

    def overwrite_field?(key, value, group_id)
      false
    end
  end

  # @private
  class StringSubstituter < BaseSubstituter
    def initialize(from_value, to_value, key = nil, group_ids = nil, opts = {})
      @from_value = from_value
      @to_value = to_value.nil? ? "" : to_value
      @from_regex = /#{::Regexp.escape(@from_value)}/
      @key = key
      @group_ids = group_ids
      @forced_overwrite = opts['forced_overwrite'].present?
    end

    def call(key, value, group_id)
      if overwrite_field?(key, value, group_id)
        @to_value
      elsif value.is_a?(String) && @from_regex != //
        value.gsub(@from_regex, @to_value)
      else
        value
      end
    end

    def overwrite_field?(key, value, group_id)
      @key == key && overwrite_fields.include?(key) && (@forced_overwrite || @from_value.presence == value.presence) &&
        @group_ids.include?(group_id)
    end

    def overwrite_fields
      %w(contact_tel contact_fax contact_email contact_link_url contact_link_name)
    end
  end

  # @private
  module HierarchySubstituterSupport
    def self.collect(from_value, to_value, key = nil, group_ids = nil, opts = {})
      from_parts = from_value.split(opts['separator'])
      to_parts = to_value.split(opts['separator'])
      from_leaf = from_parts.last
      to_leaf = to_parts.last

      substituters = [StringSubstituter.new(from_value, to_value, key, group_ids, opts)]
      substituters << StringSubstituter.new(from_leaf, to_leaf, key, group_ids, opts) if from_leaf.present? && to_leaf.present?
      if from_parts.length > 1 && from_parts.length == to_parts.length
        1.upto(from_parts.length - 1) do |index|
          from_hierarchy = to_parts[0..(index - 1)]
          from_hierarchy << from_parts[index]
          from_hierarchy = from_hierarchy.join(opts['separator'])
          to_hierarchy = to_parts[0..index].join(opts['separator'])
          if from_hierarchy.present? && to_hierarchy.present? && from_hierarchy != to_hierarchy
            substituters << StringSubstituter.new(from_hierarchy, to_hierarchy, key, group_ids, opts)
          end
        end
      end
      substituters
    end
  end

  # @private
  class ChainSubstituter
    def initialize(substituters = [], opts = {})
      @substituters = [] + substituters
      @sorted = false
      @opts = opts
      @opts['separator'] = '/'
    end

    def config
      SS.config.chorg
    end

    def collect(from, to, group_ids = nil)
      to.each do |k, v|
        from_value = from[k] || ''
        to_value = v || ''
        next if from_value == to_value

        if config.ids_fields.include?(k.to_s)
          @substituters << IdSubstituter.new(from_value, to_value, k, group_ids)
        elsif from_value.is_a?(String) && to_value.is_a?(String)
          if from_value.include?(@opts['separator'])
            @substituters += HierarchySubstituterSupport.collect(from_value, to_value, k, group_ids, @opts)
          else
            @substituters << StringSubstituter.new(from_value, to_value, k, group_ids, @opts)
          end
        end
      end
      @sorted = false
      self
    end

    def call(key, value, group_id)
      unless @sorted
        @substituters.sort!
        @sorted = true
      end
      @substituters.reduce(value) do |a, e|
        break e.to_value if e.overwrite_field?(key, value, group_id)
        e.call(key, a, group_id)
      end
    end

    def empty?
      @substituters.empty?
    end
  end

  def self.new(opts = {})
    ChainSubstituter.new([], opts)
  end

  def self.collect(from, to, group_id = nil, opts = {})
    ChainSubstituter.new([], opts).collect(from, to, group_id)
  end
end
