module SS::CatchAllFilter
  extend ActiveSupport::Concern

  def index
    raise ActionController::RoutingError, "No route matches #{SS.request_path(request)}"
  end
end
