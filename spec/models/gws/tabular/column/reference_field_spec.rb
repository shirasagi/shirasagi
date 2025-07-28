require 'spec_helper'

describe Gws::Tabular::Column::ReferenceField, type: :model, dbscope: :example do
  describe ".use_required" do
    it do
      expect(described_class.use_required).to be_truthy
    end
  end

  describe ".use_reference_type" do
    it do
      expect(described_class.use_reference_type).to be_truthy
    end
  end
end
