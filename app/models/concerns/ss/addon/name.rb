class SS::Addon::Name
  def initialize(mod, params = {})
    @klass = mod
    @name  = mod.to_s.underscore.sub("addon/", "")
  end

  def klass
    @klass
  end

  def name
    I18n.t "modules.addons.#{@name}", default: @name.titleize
  end

  def path
    @name.sub("/", "/agents/addons/")#.pluralize
  end

  def id
    path.gsub('/', '-')
  end

  def controller_file
    file = "#{Rails.root}/app/controllers/#{self.path}_controller.rb"
    File.exists?(file) ? path : nil
  end

  def show_file
    file = "#{Rails.root}/app/views/#{path}/_show.html.erb"
    File.exists?(file) ? file : nil
  end

  def form_file
    file = "#{Rails.root}/app/views/#{path}/_form.html.erb"
    File.exists?(file) ? file : nil
  end

  def view_file
    file = "#{Rails.root}/app/views/#{path}/view/index.html.erb"
    File.exists?(file) ? file : nil
  end
end
