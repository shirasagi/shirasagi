class Inquiry::Apis::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::AjaxFilter

  model Inquiry::Column

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
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def update
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    result = @item.save
    unless result
      # 成功した場合は親フレームを更新するが、失敗した場合はダイアログ内のフレームを更新する
      @turbo_frame = params[:_error_frame].to_s if params.key?(:_error_frame)
      render template: "edit", status: :unprocessable_content
      return
    end

    redirect_to inquiry_frames_column_path(id: @item, ref: ref), notice: t("ss.notice.saved")
  end
end
