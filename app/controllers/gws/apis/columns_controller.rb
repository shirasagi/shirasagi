class Gws::Apis::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include SS::AjaxFilter

  model Gws::Column::Base

  private

  def set_item
    super
    @model = @item.try(:class)
  end

  def cur_form
    @cur_form ||= @item.form
  end

  def ref
    ret = params[:ref]
    return SS.request_path(request) if ret.blank?
    return SS.request_path(request) unless trusted_url?(ret)
    ret
  end

  public

  def edit
    raise "403" unless cur_form.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def update
    raise "403" unless cur_form.allowed?(:edit, @cur_user, site: @cur_site)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    result = @item.save
    unless result
      render template: "edit", status: :unprocessable_entity
      return
    end

    redirect_to gws_frames_column_path(id: @item, ref: ref), notice: t("ss.notice.saved")
  end
end
