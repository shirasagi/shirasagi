class SS::Extensions::Decimal128

  def initialize(*args)
    val = args.first

    if val.is_a?(::BigDecimal)
      @value = val
    elsif val.is_a?(BSON::Decimal128)
      @value = val.to_big_decimal
    elsif val.numeric?
      @value = BigDecimal(val.to_s)
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

  #
  # Implements BigDecimal
  #
  delegate :precs, :hash, :to_s, :to_fs, :to_i, :to_r, :split, :to_f, :floor, :ceil, to: :value

  def add(value, digits)
    value = value.value if value.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.add(value, digits))
  end

  def sub(value, digits)
    value = value.value if value.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.sub(value, digits))
  end

  def div(value, digits)
    value = value.value if value.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.div(value, digits))
  end

  def mult(value, digits)
    value = value.value if value.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.mult(value, digits))
  end

  def +(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value + other)
  end

  def -(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value - other)
  end

  def +@
    self
  end

  def -@
    self.class.new(- self.value)
  end

  def *(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value * other)
  end

  def /(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value / other)
  end

  def quo(numeric)
    numeric = numeric.value if numeric.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.quo(numeric))
  end

  def abs
    self.class.new(self.value.abs)
  end

  def sqrt(numeric)
    numeric = numeric.value if numeric.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.sqrt(numeric))
  end

  def fix
    self.class.new(self.value.fix)
  end

  def round(*args)
    ret = self.value.round(*args)
    ret.is_a?(BigDecimal) ? self.class.new(ret) : ret
  end

  def frac
    self.class.new(self.value.frac)
  end

  def power(*args)
    n, prec = *args
    n = n.value if n.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.power(n, prec))
  end

  def **(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value ** other)
  end

  #
  # Implements Numeric
  #
  delegate :to_c, :real, :imaginary, :imag, :abs2, :arg, :angle, :phase, :rectangular, :rect, to: :value
  delegate :polar, :conjugate, :conj, :singleton_method_added, :initialize_copy, :coerce, :i, to: :value
  delegate :to_int, :real?, :integer?, :zero?, :nonzero?, :finite?, :infinite?, :floor, :ceil, to: :value
  delegate :truncate, :step, :positive?, :negative?, :numerator, :denominator, :quo, to: :value

  def <=>(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.value <=> other
  end

  def eql?(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.value.eql?(other)
  end

  def fdiv(numeric)
    numeric = numeric.value if numeric.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.fdiv(numeric))
  end

  def divmod(numeric)
    numeric = numeric.value if numeric.is_a?(SS::Extensions::Decimal128)
    q, r = self.value.divmod(numeric)
    [ self.class.new(q), self.class.new(r) ]
  end

  def %(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value % other)
  end

  def modulo(numeric)
    numeric = numeric.value if numeric.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.modulo(numeric))
  end

  def remainder(numeric)
    numeric = numeric.value if numeric.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.remainder(numeric))
  end

  alias magnitude abs

  #
  # Implements Comparable
  #
  def ==(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.value == other
  end
  alias === ==

  def >(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.value > other
  end

  def >=(other)
    (self > other) || (self == other)
  end

  def <(other)
    other = other.value if other.is_a?(SS::Extensions::Decimal128)
    self.value < other
  end

  def <=(other)
    (self < other) || (self == other)
  end

  def between?(min, max)
    min = min.value if min.is_a?(SS::Extensions::Decimal128)
    max = max.value if max.is_a?(SS::Extensions::Decimal128)
    self.value.between?(min, max)
  end

  def clamp(min, max)
    min = min.value if min.is_a?(SS::Extensions::Decimal128)
    max = max.value if max.is_a?(SS::Extensions::Decimal128)
    self.class.new(self.value.clamp(min, max))
  end

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
