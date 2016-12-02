class Jmaxml::Renderer::Base < AbstractController::Base

  abstract!

  include AbstractController::Rendering
  include AbstractController::Logger
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  include AbstractController::Callbacks
  include ActionView::Layouts

  private_class_method :new

  helper Jmaxml::RendererHelper
  helper ::ApplicationHelper

  class << self
    def renderer_name
      @renderer_name ||= anonymous? ? "anonymous" : name.underscore
    end
    # Allows to set the name of current mailer.
    attr_writer :renderer_name
    alias controller_path renderer_name

    def method_missing(method_name, *args) # :nodoc:
      if action_methods.include?(method_name.to_s)
        new.process(method_name, *args)
      else
        super
      end
    end
  end

  prepend_view_path(SS::Application.config.paths["app/views"].existent)

  def self.inherited(child)
    child.cattr_accessor(:page_class) { Article::Page }
  end

  attr_internal :page

  def initialize
    @_page = self.class.page_class.new
  end

  def page(attributes = {}, &block)
    @_page.attributes = attributes.except(:parts_order, :content_type, :body, :template_name, :template_path)
    responses = collect_responses(attributes, &block)
    @_page.html = responses.first[:html]
    @_page
  end

  def collect_responses(headers, &block)
    responses = []

    if headers[:html]
      responses << {
        html: headers.delete(:html),
        content_type: self.class.default[:content_type] || "text/html"
      }
    else
      templates_path = headers.delete(:template_path) || self.class.renderer_name
      templates_name = headers.delete(:template_name) || action_name

      each_template(Array(templates_path), templates_name) do |template|
        self.formats = template.formats

        responses << {
          html: render(template: template),
          content_type: template.type.to_s
        }
      end
    end

    responses
  end

  def each_template(paths, name, &block)
    templates = lookup_context.find_all(name, paths)
    if templates.empty?
      raise ActionView::MissingTemplate.new(paths, name, paths, false, 'renderer')
    else
      templates.uniq { |t| t.formats }.each(&block)
    end
  end
end
