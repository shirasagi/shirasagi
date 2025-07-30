class Gws::Workflow2::Form::Application < Gws::Workflow2::Form::Base
  include Gws::Workflow2::ApplicationSetting
  include Gws::Addon::Workflow2::DestinationSetting
  include Gws::Addon::Workflow2::ColumnSetting

  # # indexing to elasticsearch via companion object
  # update_form do |form|
  #   skip = form.columns.last.try(:skip_elastic)
  #   ::Gws::Elasticsearch::Indexer::Workflow2FormJob.around_save(form) { true } unless skip
  # end

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
