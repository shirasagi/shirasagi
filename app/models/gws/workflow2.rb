module Gws::Workflow2
  extend Gws::ModulePermission

  module_function

  def keyword_operator_options
    %w(and or).map do |v|
      [ I18n.t("gws/workflow2.options.search_operator.#{v}"), v ]
    end
  end
end
