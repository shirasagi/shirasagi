class SS::OptionsForSelectComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :options, :selected

  def group_by_options
    grouped_options = options.map do |option|
      label = option[0]
      group, label = label.split('/', 2)
      if label.blank?
        label = group
        group = nil
      end

      [ group, label, *option[1..-1] ]
    end

    loop do
      break if grouped_options.blank?

      option = grouped_options.shift
      group = option[0]
      label = option[1]
      remains = option[2..-1]

      same_group_options = grouped_options.select { |option| option[0] == group }
      same_group_options.each { |option| grouped_options.delete(option) }

      overall_options = [ [ label, *remains ] ]
      same_group_options.each do |option|
        overall_options << option[1..-1]
      end

      yield group, overall_options
    end
  end
end
