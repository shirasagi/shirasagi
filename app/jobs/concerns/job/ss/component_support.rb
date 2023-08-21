module Job::SS::ComponentSupport
  extend ActiveSupport::Concern

  def generate_component(component, **args, &block)
    raise "component is not cacheable" unless component.is_a?(SS::CacheableComponent)
    return unless component.cache_configured?

    component.delete_cache

    @controller_class ||= ViewComponent::Base.test_controller.constantize
    @controller ||= @controller_class.new.extend(Rails.application.routes.url_helpers)
    @controller.request = ActionDispatch::Request.new("rack.input" => "", "REQUEST_METHOD" => "GET")
    @controller.view_context.render(component, args, &block)
  end
end
