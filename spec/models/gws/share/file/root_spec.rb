require 'spec_helper'

RSpec.describe Gws::Share::File, type: :model, dbscope: :example do
  describe ".root" do
    it do
      expect(described_class.root).to start_with("#{Rails.root}/tmp/rspec-")
    end
  end
end
