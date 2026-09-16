#frozen_string_literal: true

class SS::DialogButtonComponent < ApplicationComponent
  include ActiveModel::API

  attr_accessor :cur_site, :cur_user, :name, :url, :html_options, :wrapper_options
  attr_writer :show_button, :open

  renders_one :template

  def show_button
    return @show_button if instance_variable_defined?(:@show_button)
    @show_button = true
  end
  alias show_button? show_button

  def open
    return @open if instance_variable_defined?(:@open)
    @open = false
  end
  alias open? open

  def dialog_options
    @dialog_options ||= begin
      options = wrapper_options.present? ? wrapper_options.stringify_keys : {}
      if options.key?("data")
        data_options = options.delete("data")
        data_options.each do |key, value|
          options["data-#{key}"] = value
        end
      end
      if options.key?("data-controller")
        options["data-controller"] = "ss--dialog #{options["data-controller"]}"
      else
        options["data-controller"] = "ss--dialog"
      end
      if open?
        options["data-ss--dialog-open-value"] = "true"
      end
      options
    end
  end

  def button_options
    @button_options ||= begin
      options = html_options.present? ? html_options.stringify_keys : {}
      options["type"] = "button" unless options.key?("type")
      options["name"] = nil unless options.key?("name")
      if options.key?("data")
        data_options = options.delete("data")
        data_options.each do |key, value|
          options["data-#{key}"] = value
        end
      end
      if options.key?("data-action")
        options["data-action"] = "ss--dialog#open #{options["data-action"]}"
      else
        options["data-action"] = "ss--dialog#open"
      end
      options
    end
  end
end
