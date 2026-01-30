module SS::AgentFilter
  extend ActiveSupport::Concern

  # inquiry/agents/parts/feedback は inquiry/node/form 配下であることが必須。
  #
  # cms/agents/nodes/photo_album_controller でセットした @cur_parent（クラス article/node/page のインスタンス） が、
  # app/views/inquiry/agents/parts/feedback/index.erb で不正に利用されることを防ぐ目的で、
  # 継承可能なインスタンス変数をホワイトリスト方式とする。
  INHERITABLE_VARIABLES = begin
    allowed_variables = %i[
      @csrf_token
      @cur_path @cur_main_path @filters @preview @translate_target @translate_source
      @task @cur_site @cur_node @cur_page @cur_part @cur_date
    ]
    Set.new(allowed_variables)
  end.freeze

  included do
    before_action :inherit_variables
  end

  private

  def controller
    @controller
  end

  def inherit_variables
    variable_names = controller.instance_variables
    variable_names = variable_names.select { INHERITABLE_VARIABLES.include?(_1.to_sym) }
    variable_names.each do |name|
      next if instance_variable_defined?(name)

      variable_value = controller.instance_variable_get(name)
      next if variable_value.nil?

      instance_variable_set name, variable_value
    end
  end

  public

  def stylesheets
    controller.stylesheets
  end

  def stylesheet(path, **options)
    controller.stylesheet(path, **options)
  end

  def javascripts
    controller.javascripts
  end

  def javascript(path, **options)
    controller.javascript(path, **options)
  end

  def opengraph(key, *values)
    controller.opengraph(key, *values)
  end

  def twitter_card(key, *values)
    controller.twitter_card(key, *values)
  end

  def filters
    @filters ||= begin
      request.env["ss.filters"] ||= []
    end
  end

  def filter_include?(key)
    filters.any? { |f| f == key || f.is_a?(Hash) && f.key?(key) }
  end

  def filter_include_any?(*keys)
    keys.any? { |key| filter_include?(key) }
  end

  def filter_options(key)
    found = filters.find { |f| f == key || f.is_a?(Hash) && f.key?(key) }
    return if found.nil?
    return found[key] if found.is_a?(Hash)
    true
  end

  def mobile_path?
    filter_include?(:mobile)
  end

  def preview_path?
    filter_include?(:preview)
  end

  def javascript_configs
    controller.javascript_configs
  end

  def javascript_config(conf)
    controller.javascript_config(conf)
  end
end
