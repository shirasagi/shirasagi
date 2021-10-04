class Cms::PartAgent < SS::Agent
  class << self
    def attach(part, options)
      options = options.dup

      cur_site = options[:cur_site] || (options[:cur_site] = part.site)
      method = options[:method] || (options[:method] = "GET")

      path = options[:path] || (options[:path] = "/.s#{cur_site.id}/parts/#{part.route}")
      spec = options[:spec] || (options[:spec] = Rails.application.routes.recognize_path(path, { method: method }))
      return if spec[:cell].blank?

      controller_name = part.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

      options[:cur_part] ||= part
      new(part, controller_name, options)
    end
  end

  attr_reader :part, :options

  def initialize(part, controller, options)
    @part = part
    @options = options

    super(controller)

    self.controller.params
    self.controller.request = ActionDispatch::Request.new(new_env)
    self.controller.instance_variable_set :@cur_site, options[:cur_site]
    self.controller.instance_variable_set :@cur_page, options[:cur_page]
    self.controller.instance_variable_set :@cur_part, part
    self.controller.instance_variable_set :@cur_path, options[:cur_path]
    self.controller.instance_variable_set :@cur_main_path, options[:cur_main_path]
    self.controller.instance_variable_set :@cur_date, options[:cur_date]
  end

  def render
    super options[:spec][:action]
  end

  private

  def new_env
    server_name, server_port = options[:cur_site].domain.split(":")

    {
      "REQUEST_METHOD" => @options[:method],
      "PATH_INFO" => @options[:path],
      "SERVER_NAME" => server_name,
      "SERVER_PORT" => server_port && server_port.numeric? ? server_port : "80",
      "rack.version" => [1, 3],
      "rack.input" => StringIO.new
    }
  end
end
