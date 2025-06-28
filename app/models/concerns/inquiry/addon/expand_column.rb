module Inquiry::Addon::ExpandColumn
  extend ActiveSupport::Concern

  module ClassMethods
    def route_options
      plugins.select { |plugin| plugin.enabled? }.map { |plugin| [plugin.name, plugin.path] }
    end
  end

  def form
    node
  end

  def path
    "inquiry/agents/columns/#{input_type}"
  end

  def column_form_partial_path
    "#{path}/column_form" if File.exist?("#{Rails.root}/app/views/#{path}/_column_form.html.erb")
  end

  def _type
    ## _type を利用するのであればDBの更新が必要(未実装)
    Cms::Column::TextField.to_s
  end

  def value_type
    Cms::Column::Value::TextField
  end

  def required?
    required == 'required'
  end

  def tooltips
    nil
  end

  def alignment_options
    []
  end

  def form_options
    {}
  end
end
