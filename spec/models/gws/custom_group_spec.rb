require 'spec_helper'

describe Gws::CustomGroup, type: :model, dbscope: :example do
  let(:model) { described_class }

  describe "validation" do
    it { expect(model.new.save).to be_falsey }
  end

  describe "scopes" do
    let!(:item) { create :gws_custom_group }

    it "search" do
      ret = model.search(keyword: item.name).exists?
      expect(ret).to eq true
    end
  end
end
