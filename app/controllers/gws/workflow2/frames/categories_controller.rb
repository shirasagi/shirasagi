class Gws::Workflow2::Frames::CategoriesController < ApplicationController
  include Gws::ApiFilter
  include Gws::CategoryFrame

  model Gws::Workflow2::Form::Category

  private

  def category_param
    @category_param ||= params.dig(:s, :category_filter)
  end

  def url_for_category_decide
    url_for(
      action: :index,
      s: { category_filter: "$(category_id)" },
      "gws/category_frame" => { only: "simple", action_btn: "decide" })
  end

  def return_path
    return @return_path if instance_variable_defined?(:@return_path)

    return_path = category_frame_options[:return_path].to_s
    if return_path.present?
      @return_path = Addressable::URI.parse(return_path).request_uri
    else
      @return_path = gws_workflow2_select_forms_path(s: { category_filter: "$(category_id)" })
    end
  end
end
