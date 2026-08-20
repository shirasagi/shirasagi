#frozen_string_literal: true

class SS::DialogButtonComponent < ApplicationComponent
  include ActiveModel::API

  attr_accessor :cur_site, :cur_user, :name, :url, :html_options
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

  def button_options
    @button_options ||= begin
      options = html_options.present? ? html_options.stringify_keys : {}
      options["type"] = "button" unless options.key?("type")
      options["name"] = nil unless options.key?("name")
      if options.key?("data-action")
        options["data-action"] = "#{options["data-action"]} ss--dialog#open"
      else
        options["data-action"] = "ss--dialog#open"
      end
      options
    end
  end
end
