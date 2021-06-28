class SS::Agent
  attr_accessor :controller

  def initialize(controller)
    if controller.is_a?(String)
      controller = "#{controller}_controller".camelize.constantize
    end
    @controller = controller.new
    @controller.params   = ActionController::Parameters.new
    @controller.request  = ActionDispatch::Request.new("rack.input" => "", "REQUEST_METHOD" => "GET")
    @controller.response = ActionDispatch::Response.new

    #@controller.params.merge! opts[:params] if opts[:params]
    #@controller.request.env.merge! opts[:request] if opts[:request]
  end

  class << self
    def invoke_action(controller_name, action, variables)
      cont = controller_name.camelize
      cname = cont + "Controller"

      agent = SS::Agent.new(controller_name) rescue nil
      return if agent.blank? || agent.controller.class.to_s != cname
      return unless agent.controller.respond_to?(action)

      variables.each do |key, value|
        agent.controller.instance_variable_set("@#{key}".to_sym, value)
      end
      agent.controller.params[:controller] = controller_name
      agent.controller.params[:action] = action.to_s
      agent.invoke(action)
    end
  end

  def invoke(action)
    @controller.instance_eval do |obj|
      def obj.render(*args); end
    end

    @controller.params[:action] = action
    @controller.process action
    @controller
  end

  def render(action)
    @controller.params[:action] = action
    @controller.process action
    @controller.response
  end
end
