class Inquiry::Frames::ColumnsController < ApplicationController
  include Cms::ApiFilter

  layout "ss/item_frame"
  model Inquiry::Column

  before_action :set_frame_id
  helper_method :ref, :item

  alias item set_item

  private

  def set_frame_id
    @frame_id ||= "item-#{item.id}"
  end

  def ref
    @ref ||= begin
      ref = params[:ref].to_s.presence
      if ref && !Sys::TrustedUrlValidator.valid_url?(ref)
        ref = nil
      end

      ref.presence
    end
  end

  def model
    @item ? @item.class : Inquiry::Column
  end

  def set_item
    @item ||= begin
      item = @model.find(params[:id].to_i)
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def show
    raise "403" unless @item.form.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def edit
    raise "403" unless @item.form.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def update
    raise "403" unless @item.form.allowed?(:edit, @cur_user, site: @cur_site)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    unless @item.save
      render template: "edit", status: :unprocessable_content
      return
    end

    flash[:notice] = t("ss.notice.saved")
    render template: "show"
  end

  def destroy
    raise "403" unless @item.form.allowed?(:delete, @cur_user, site: @cur_site)

    unless @item.destroy
      render template: "show", status: :unprocessable_content
      return
    end

    json = { status: 200, notice: t("ss.notice.deleted") }
    render json: json, status: :ok, content_type: json_content_type
  end
end
