class SS::Extensions::Decimal128

  def initialize(*args)
    val = args.first

    if val.is_a?(::BigDecimal)
      @value = val
    elsif val.is_a?(BSON::Decimal128)
      @value = val.to_big_decimal
    elsif val.numeric?
      @value = ::BigDecimal.new(val.to_s)
    else
      raise ArgumentError, "invalid value for SS::Extensions::Decimal128(): \"#{val}\""
    end
  end

  attr_accessor :value

  # Convert the big decimal to an $inc-able value.
  #
  # @return [ Float ] The big decimal as a float.
  def __to_inc__
    @value.to_f
  end

  # Convert an object from the ruby type into a Mongo friendly type.
  #
  # @return [ Object ] The object.
  def mongoize
    BSON::Decimal128.new(@value)
  end

  delegate :%, :modulo, :*, :**, :power, :+, :-, :+@, :-@, :/, :div, :quo, to: :value
  delegate :<, :<=, :<=>, :==, :eql?, :>, :>=, to: :value
  delegate :abs, :add, :ceil, :div, :divmod, :exponent, :finite?, :fix, :floor, :frac, :hash, :infinite?, to: :value
  delegate :mult, :nan?, :nonzero?, :precs, :remainder, :round, :sign, :split, :sqrt, :sub, to: :value
  delegate :to_f, :to_i, :to_int, :to_r, :to_s, to: :value
  delegate :truncate, :zero?, to: :value

  class << self
    # Convert the object from its mongo friendly ruby type to this type.
    #
    # @param [ Object ] object The object to demongoize.
    #
    # @return [ Object ] The object.
    def demongoize(object)
      if object.is_a?(::BigDecimal)
        new(object)
      elsif object.is_a?(BSON::Decimal128)
        new(object.to_big_decimal)
      elsif object.numeric?
        new(object.to_s)
      end
    end

    # Mongoize an object of any type to how it's stored in the db as a big
    # decimal.
    #
    # @param [ Object ] object The object to Mongoize
    #
    # @return [ String ] The mongoized object.
    def mongoize(object)
      if object.is_a?(SS::Extensions::Decimal128)
        object.mongoize
      elsif object.is_a?(::BigDecimal) || object.is_a?(BSON::Decimal128) || object.numeric?
        new(object).mongoize
      end
    end
  end
end
