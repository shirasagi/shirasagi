class SS::Addon::Name
  def initialize(mod, params = {})
    @klass = mod
    underscore = mod.to_s.underscore.sub("addon/", "")
    @name = I18n.t("modules.addons.#{underscore}", default: underscore.titleize)
    @path = underscore.sub("/", "/agents/addons/")
    @id = @path.tr('/', '-')
    @type = params[:type]
  end

  attr_reader :klass, :name, :path, :type, :id

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
