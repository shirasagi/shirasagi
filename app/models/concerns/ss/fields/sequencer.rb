module SS::Fields::Sequencer
  extend ActiveSupport::Concern

  module ClassMethods
    def sequence_field(name)
      fields = instance_variable_get(:@_sequenced_fields) || []
      instance_variable_set(:@_sequenced_fields, fields << name)
      before_save :set_sequence
    end
  end

  public
    def next_sequence(name)
      SS::Sequence.next_sequence collection_name, name
    end

    def unset_sequence(name)
      SS::Sequence.unset_sequence collection_name, name
    end

  private
    def set_sequence
      self.class.instance_variable_get(:@_sequenced_fields).each do |name|
        next if self[name].to_s =~ /^[1-9]\d*$/
        self[name] = next_sequence(name)
      end
    end
end
