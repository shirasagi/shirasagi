module Chorg::Substitutor
  # @private
  class BaseSubstitutor
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
  class IdSubstitutor < BaseSubstitutor
    def initialize(from_value, to_value, key = nil, group_ids = nil)
      super()
      @from_value = from_value
      @to_value = to_value
      @first_to_value = @to_value.is_a?(Array) ? @to_value.first : @to_value
      @key = key
      @group_ids = group_ids
    end

    def call(key, value, group_id)
      if value.is_a?(Integer)
        value == @from_value ? @first_to_value : value
      elsif integer_array?(value)
        substitute_array(value)
      else
        value
      end
    end

    def integer_array?(array_value)
      return false if !array_value.is_a?(Array)
      return false if array_value.to_a.select { |value| value && !value.is_a?(Integer) }.first
      true
    end

    def substitute_array(array_value)
      array_value.map { |e| e == @from_value ? @to_value : e }.flatten.uniq
    end

    def overwrite_field?(key, value, group_id)
      false
    end
  end

  # @private
  class StringSubstitutor < BaseSubstitutor
    def initialize(from_value, to_value, key = nil, group_ids = nil, opts = {})
      super()
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
      elsif string_array?(value)
        substitute_array(value)
      else
        value
      end
    end

    def overwrite_field?(key, value, group_id)
      @key == key && overwrite_fields.include?(key) && (@forced_overwrite || @from_value.presence == value.presence) &&
        @group_ids.include?(group_id)
    end

    def overwrite_fields
      %w(contact_group_name contact_charge contact_tel contact_fax contact_email contact_link_url contact_link_name)
    end

    def string_array?(array_value)
      return false if !array_value.is_a?(Array)
      return false if array_value.to_a.select { |value| value && !value.is_a?(String) }.first
      true
    end

    def substitute_array(array_value)
      new_value = array_value.to_a.map do |value|
        if value.is_a?(String) && @from_regex != //
          value.gsub(@from_regex, @to_value)
        else
          value
        end
      end
      array_value.class.new(new_value)
    end
  end

  # @private
  module HierarchySubstitutorSupport
    def self.collect(from_value, to_value, key = nil, group_ids = nil, opts = {})
      from_parts = from_value.split(opts['separator'])
      to_parts = to_value.split(opts['separator'])
      from_leaf = from_parts.last
      to_leaf = to_parts.last

      substitutors = [StringSubstitutor.new(from_value, to_value, key, group_ids, opts)]
      substitutors << StringSubstitutor.new(from_leaf, to_leaf, key, group_ids, opts) if from_leaf.present? && to_leaf.present?
      if from_parts.length > 1 && from_parts.length == to_parts.length
        1.upto(from_parts.length - 1) do |index|
          from_hierarchy = from_parts[0..(index - 1)]
          from_hierarchy << from_parts[index]
          from_hierarchy = from_hierarchy.join(opts['separator'])
          to_hierarchy = to_parts[0..index].join(opts['separator'])

          next if from_hierarchy.blank? || to_hierarchy.blank?
          next if from_hierarchy == to_hierarchy
          next if ignore_hierarchy?(from_hierarchy) || ignore_hierarchy?(to_hierarchy)

          substitutors << StringSubstitutor.new(from_hierarchy, to_hierarchy, key, group_ids, opts)
        end
      end
      substitutors
    end

    def self.ignore_hierarchy?(hierarchy)
      [ "http:/", "https:/" ].include?(hierarchy)
    end
  end

  # @private
  module GroupHierarchySubstitutorSupport
    def self.collect(from_value, to_value, key = nil, group_ids = nil, opts = {})
      from_parts = from_value.split(opts['separator'])
      to_parts = to_value.split(opts['separator'])
      from_leaf = from_parts.last
      to_leaf = to_parts.last

      substitutors = [StringSubstitutor.new(from_value, to_value, key, group_ids, opts)]
      if from_leaf.present? && to_leaf.present? && from_leaf != to_leaf
        substitutors << StringSubstitutor.new(from_leaf, to_leaf, key, group_ids, opts)
      end
      substitutors
    end
  end

  # @private
  class ChainSubstitutor
    def initialize(substitutors = [], opts = {})
      @substitutors = [] + substitutors
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

        if config.ids_fields.include?(k.to_s)
          @substitutors << IdSubstitutor.new(from_value, to_value, k, group_ids)
        elsif from_value.is_a?(String) && to_value.is_a?(String)
          if from_value.include?(@opts['separator'])
            @substitutors += GroupHierarchySubstitutorSupport.collect(from_value, to_value, k, group_ids, @opts)
          else
            @substitutors << StringSubstitutor.new(from_value, to_value, k, group_ids, @opts)
          end
        end
      end
      @sorted = false
      self
    end

    def call(key, value, group_id)
      unless @sorted
        @substitutors.sort!
        @sorted = true
      end
      @substitutors.reduce(value) do |a, e|
        break e.to_value if e.overwrite_field?(key, value, group_id)
        e.call(key, a, group_id)
      end
    end

    def empty?
      @substitutors.empty?
    end
  end

  def self.new(opts = {})
    ChainSubstitutor.new([], opts)
  end

  def self.collect(from, to, group_id = nil, opts = {})
    ChainSubstitutor.new([], opts).collect(from, to, group_id)
  end
end
