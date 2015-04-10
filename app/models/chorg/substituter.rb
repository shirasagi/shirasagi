module Chorg::Substituter
  # @private
  class BaseSubstituter
    include Comparable

    attr_reader :from_value, :to_value

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
    def initialize(from_value, to_value)
      raise if to_value.nil?
      @from_value = from_value
      @to_value = to_value
      @first_to_value = @to_value.is_a?(Array) ? @to_value.first : @to_value
    end

    def call(value)
      if value.is_a?(Fixnum)
        value == @from_value ? @first_to_value : value
      elsif value.is_a?(Enumerable)
        value.map { |e| e == @from_value ? @to_value : e }.flatten.uniq
      else
        value
      end
    end
  end

  # @private
  class StringSubstituter < BaseSubstituter
    def initialize(from_value, to_value)
      raise if from_value.blank?
      raise if to_value.blank?
      @from_value = from_value
      @to_value = to_value.nil? ? "" : to_value
      @from_regex = /#{Regexp.escape(@from_value)}/
    end

    def call(value)
      if value.is_a?(String)
        value.gsub(@from_regex, @to_value)
      else
        value
      end
    end
  end

  # @private
  module HierarchySubstituterSupport
    def self.collect(from_value, to_value, separator)
      # to_value = to_value.nil? ? "" : to_value
      raise if from_value.blank?
      raise if to_value.blank?
      from_parts = from_value.split(separator)
      to_parts = to_value.split(separator)
      from_leaf = from_parts.last
      to_leaf = to_parts.last

      substituters = [StringSubstituter.new(from_value, to_value)]
      substituters << StringSubstituter.new(from_leaf, to_leaf) if from_leaf.present? && to_leaf.present?
      if from_parts.length > 1 && from_parts.length == to_parts.length
        1.upto(from_parts.length - 1) do |index|
          from_hierarchy = to_parts[0..(index - 1)]
          from_hierarchy << from_parts[index]
          from_hierarchy = from_hierarchy.join(separator)
          to_hierarchy = to_parts[0..index].join(separator)
          substituters << StringSubstituter.new(from_hierarchy, to_hierarchy) \
            if from_hierarchy.present? && to_hierarchy.present? && from_hierarchy != to_hierarchy
        end
      end
      substituters
    end
  end

  # @private
  class ChainSubstituter
    def initialize(substituters = [])
      @substituters = [] + substituters
      @sorted = false
    end

    def config
      SS.config.chorg
    end

    def collect(from, to)
      from.each do |k, v|
        from_value = v
        next if from_value.blank?
        to_value = to[k]
        next if to_value.blank? || from_value == to_value

        if config.ids_fields.include?(k.to_s)
          @substituters << IdSubstituter.new(from_value, to_value)
        elsif from_value.is_a?(String)
          if from_value.include?("/")
            @substituters += HierarchySubstituterSupport.collect(from_value, to_value, "/")
          else
            @substituters << StringSubstituter.new(from_value, to_value)
          end
        end
      end
      @sorted = false
      self
    end

    def call(value)
      unless @sorted
        @substituters.sort!
        @sorted = true
      end
      @substituters.reduce(value) do |a, e|
        e.call(a)
      end
    end

    def empty?
      @substituters.empty?
    end
  end

  def self.new
    ChainSubstituter.new
  end

  def self.collect(from, to)
    ChainSubstituter.new.collect(from, to)
  end
end
