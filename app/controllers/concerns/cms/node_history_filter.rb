module Cms::NodeHistoryFilter
  extend ActiveSupport::Concern

  NODE_HISTORY_LIMIT = 10

  included do
    after_action :update_node_history, only: %i[index file] # "file" for uploader
  end

  def update_node_history
    return unless @cur_node
    return unless @cur_node.is_a?(Cms::Model::Node)
    # return unless @cur_node.persisted?

    session_cms = session[:cms]
    session_cms ||= {}

    node_histories = session_cms[:node_histories] ||= []
    node_histories.delete(@cur_node.id)
    node_histories.prepend(@cur_node.id)
    node_histories = node_histories.take(NODE_HISTORY_LIMIT)
    session_cms[:node_histories] = node_histories
  end
end
