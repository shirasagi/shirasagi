module SS::CatchAllFilter
  extend ActiveSupport::Concern

  def index
    raise ActionController::RoutingError, "No route matches #{request.path}"
  end
end
