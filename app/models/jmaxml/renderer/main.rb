class Jmaxml::Renderer::Main < Jmaxml::Renderer::Base
  include Jmaxml::Helper::Main

  attr_reader :xmldoc

  def self.inherited(child)
    child.append_view_path "#{Rails.root}/app/views/#{child.renderer_name}"
    child.append_view_path "#{Rails.root}/app/views/#{self.renderer_name}"
  end

  def template_paths
    [ self.class.renderer_name, Jmaxml::Renderer::Main.renderer_name ]
  end

  def create(page, context, action)
    @context = context
    @action = action
    @xmldoc = @context.xmldoc
    if head_info_type == '取消'
      page(template_path: template_paths, template_name: 'cancel')
    else
      page(template_path: template_paths)
    end
  end

  def render_title
    head_title
  end

  def publishing_offices
    names = office_info_names
    return names if names.present?
    [ control_publishing_office ]
  end
end
