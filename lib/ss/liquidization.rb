module SS::Liquidization
  extend ActiveSupport::Concern

  class LiquidExportsBase < Liquid::Drop
    def self.export(*args, &block)
      options = args.extract_options!
      options = options.dup

      export_name = options[:as] || args.first
      raise "export name is required" if export_name.blank?
      raise "block is required" if args.first.nil? && !block

      define_method(export_name.to_s) do
        if block
          @delegatee.instance_exec(@context, &block)
        else
          @delegatee.send(args.first)
        end
      end
    end

    attr_reader :delegatee

    def initialize(delegatee)
      @delegatee = delegatee
    end
  end

  module ClassMethods
    def liquidize(&block)
      if const_defined?(:LiquidExports, false)
        cls = const_get(:LiquidExports, false)
      elsif superclass.const_defined?(:LiquidExports, false)
        cls = const_set(:LiquidExports, Class.new(superclass.const_get(:LiquidExports, false)))
      else
        cls = const_set(:LiquidExports, Class.new(LiquidExportsBase))
      end
      cls.class_eval(&block)
    end
  end

  def to_liquid
    return if !self.class.const_defined?(:LiquidExports, true)

    cls = self.class.const_get(:LiquidExports, true)
    cls.new(self)
  end
end
