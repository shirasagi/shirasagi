class SS::Agent
  attr_accessor :controller

  public
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

    def invoke(action)
      def @controller.render(*args); end
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
