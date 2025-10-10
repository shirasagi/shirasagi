class Cms::SyntaxCheckerComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :checker_context
  attr_writer :show_auto_correct

  def show_auto_correct
    return @show_auto_correct if instance_variable_defined?(:@show_auto_correct)
    @show_auto_correct = true
  end

  def each_grouping_errors
    errors = checker_context.errors
    errors = errors.select{ _1.id.present? }
    errors = errors.sort_by { |error| error.content.column_value.try(:order) || 0 }
    group_errors = errors.group_by { _1.id }
    group_errors.each do |_id, errors|
      yield errors
    end
  end
end
