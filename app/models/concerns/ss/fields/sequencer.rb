module SS::Fields::Sequencer
  extend ActiveSupport::Concern

  module ClassMethods
    def sequence_field(name)
      fields = instance_variable_get(:@_sequenced_fields) || []
      instance_variable_set(:@_sequenced_fields, fields << name)
      before_save :set_sequence
    end

    def sequenced_fields
      @_sequenced_fields
    end
  end

  def mongo_client_options
    options = persistence_options
    return options if options
    { client: Job::Log.storage_options[:client], database: self.class.database_name}
  end

  def current_sequence(name)
    storage =
    SS::Sequence.current_sequence collection_name, name, with: mongo_client_options
  end

  def next_sequence(name)
    SS::Sequence.next_sequence collection_name, name, with: mongo_client_options
  end

  def unset_sequence(name)
    SS::Sequence.unset_sequence collection_name, name, with: mongo_client_options
  end

  private

  def set_sequence
    self.class.instance_variable_get(:@_sequenced_fields).each do |name|
      next if self[name].to_s =~ /^[1-9]\d*$/
      self[name] = next_sequence(name)
    end
  end
end
