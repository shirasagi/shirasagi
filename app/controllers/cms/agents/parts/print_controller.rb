class Cms::Agents::Parts::PrintController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    render html: view_context.button_tag(@cur_part.name, type: "button", name: "print", class: "btn-ss-print")
  end
end
