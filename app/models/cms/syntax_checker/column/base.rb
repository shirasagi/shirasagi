module Cms::SyntaxChecker::Column::Base
  extend ActiveSupport::Concern

  included do
    attr_accessor :column_value, :attribute, :params
  end

  def parsed_params
    return @parsed_params if instance_variable_defined?(:@parsed_params)

    if self.params.is_a?(Proc)
      params = column_value.instance_exec(&self.params)
    else
      params = self.params
    end

    @parsed_params = begin
      case params
      when TrueClass
        {}
      when FalseClass
        nil
      when Hash
        params
      when Range, Array
        { in: params }
      else
        { with: params }
      end
    end
  end
end
