class Gws::Affair::Apis::Overtime::ResultsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::OvertimeFile

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    if @item.update
      respond_to do |format|
        format.html { render :show, layout: false }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render render_opts }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end
end
