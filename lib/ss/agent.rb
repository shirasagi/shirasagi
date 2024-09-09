class SS::Agent
  attr_accessor :controller

  def initialize(controller_or_name)
    if controller_or_name.is_a?(String)
      controller = "#{controller_or_name}_controller".camelize.constantize
      controller_name = controller_or_name
    else
      controller = controller_or_name
      controller_name = self.class.controller_name(controller_or_name.name)
    end
    @controller_name = controller_name
    @controller = controller.new
    @controller.params   = ActionController::Parameters.new
    @controller.request  = ActionDispatch::Request.new("rack.input" => "", "REQUEST_METHOD" => "GET")
    @controller.response = ActionDispatch::Response.new

    #@controller.params.merge! opts[:params] if opts[:params]
    #@controller.request.env.merge! opts[:request] if opts[:request]
  end

  class << self
    def invoke_action(controller_name, action, variables)
      agent = SS::Agent.new(controller_name) rescue nil
      return if agent.blank?
      return unless agent.controller.respond_to?(action)

      variables.each do |key, value|
        agent.controller.instance_variable_set("@#{key}".to_sym, value)
      end
      agent.controller.params[:controller] = controller_name
      agent.controller.params[:action] = action.to_s
      agent.invoke(action)
    end

    def controller_name(class_name)
      class_name.underscore.sub("_controller", "")
    end
  end

  def invoke(action)
    @controller.instance_eval do |obj|
      def obj.render(*args); end
    end

    @controller.params[:controller] = @controller_name
    @controller.params[:action] = action
    @controller.process action
    @controller
  end

  def render(action)
    @controller.params[:controller] = @controller_name
    @controller.params[:action] = action
    @controller.process action
    @controller.response
  end
end
