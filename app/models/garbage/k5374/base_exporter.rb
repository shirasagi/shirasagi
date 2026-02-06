class Garbage::K5374::BaseExporter
  include ActiveModel::Model
  include SS::HumanAttributeName

  attr_accessor :site, :node, :task

  def initialize(cur_node, task = nil)
    @site = cur_node.site
    @node = cur_node
    @task = task
  end
end
