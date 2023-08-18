class Gws::Portal::Apis::AdFilesController < ApplicationController
  include Gws::ApiFilter

  model SS::LinkFile

  private

  def set_item
    @item ||= begin
      item = SS::File.find(params[:id])
      item = item.becomes_with(@model)
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def select
    set_item
    render template: "select", layout: !request.xhr?
  end
end
