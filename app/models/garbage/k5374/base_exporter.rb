class Garbage::K5374::BaseExporter
  include ActiveModel::Model

  attr_accessor :site, :node, :task

  def initialize(cur_node, task = nil)
    @site = cur_node.site
    @node = cur_node
    @task = task
  end

  def t(name, opts = {})
    self.class.t name, opts
  end

  class << self
    def t(*args)
      human_attribute_name *args
    end
  end
end
