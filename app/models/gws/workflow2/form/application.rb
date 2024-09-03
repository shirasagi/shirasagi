class Gws::Workflow2::Form::Application < Gws::Workflow2::Form::Base
  include Gws::Addon::Workflow2::DestinationSetting
  include Gws::Addon::Workflow2::ColumnSetting

  field :approval_state, type: String, default: "with_approval"
  field :default_route_id, type: String, default: 'my_group'
  field :agent_state, type: String, default: 'disabled'

  permit_params :approval_state, :default_route_id, :agent_state

  validates :approval_state, presence: true, inclusion: { in: %w(without_approval with_approval), allow_blank: true }
  validates :agent_state, presence: true, inclusion: { in: %w(disabled enabled), allow_blank: true }

  # # indexing to elasticsearch via companion object
  # update_form do |form|
  #   ::Gws::Elasticsearch::Indexer::Workflow2FormJob.around_save(form) { true }
  # end

  def approval_state_options
    %w(without_approval with_approval).map do |v|
      [ I18n.t("gws/workflow2.options.approval_state.#{v}"), v ]
    end
  end

  def agent_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("gws/workflow.options.agent_state.#{v}"), v ]
    end
  end

  def approval_state_without_approval?
    approval_state == "without_approval"
  end

  def approval_state_with_approval?
    !approval_state_without_approval?
  end

  def agent_enabled?
    agent_state == 'enabled'
  end

  def next_style_sequence!
    SS::Sequence.next_sequence(self.class.collection_name, "workflow-seq_#{id}", with: mongo_client_options)
  end

  def current_style_sequence
    SS::Sequence.current_sequence(self.class.collection_name, "workflow-seq_#{id}", with: mongo_client_options)
  end

  def new_file_name
    timestamp = Time.zone.now.strftime("%Y%m%d")
    seq = next_style_sequence!
    [ name, timestamp, seq ].compact.join("_")
  end
end
