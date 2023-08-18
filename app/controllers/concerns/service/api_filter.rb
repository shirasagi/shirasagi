module Service::ApiFilter
  extend ActiveSupport::Concern
  include Service::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  def index
  end
end
