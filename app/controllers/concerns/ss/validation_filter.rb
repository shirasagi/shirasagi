module SS::ValidationFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter
  include SS::CrudFilter

  private

  def fix_params
    { cur_user: @cur_user }
  end

  public

  def validate
    models = Mongoid.models.reject { |m| m.to_s.start_with?('Mongoid::') }
    @model = models.find{ |m| m.to_s == params[:model] }
    if params[:id].present?
      set_item
      @item.attributes = get_params
    else
      @item = @model.new(get_params)
    end
    @item.validate
    render json: @item.errors.to_json
  end
end
