module Cms::OpendataRef::PageFilter
  extend ActiveSupport::Concern

  def update_opendata_resources
    set_item

    safe_params = params.require(:item).permit(:file_id, :state, :dataset_id, :license_id, :text)

    file_id = safe_params[:file_id]
    key_values = safe_params.except(:file_id)
    if key_values.present? && @item.update_opendata_resources!(file_id, key_values).blank?
      return render json: [ @item.errors.full_messages ], status: :unprocessable_entity
    end

    head :no_content
  rescue => e
    render json: [ e.message ], status: :unprocessable_entity
  end
end
