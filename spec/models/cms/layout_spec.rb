require 'spec_helper'

describe Cms::Layout do
  subject(:model) { Cms::Layout }
  subject(:factory) { :cms_layout }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }

    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.json_path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.json_path).not_to eq nil }
    it { expect(item.public?).not_to eq nil }
    it { expect(item.parent).to eq false }
  end

  describe "validation" do
    it "basename" do
      item = build(:cms_node_node_basename_invalid)
      expect(item.invalid?).to be_truthy
    end

    context "duplicated filename" do
      let(:entity1) { build(:cms_layout, name: "layout1", filename: "layout1.layout.html") }
      let(:entity2) { build(:cms_layout, name: "layout2", filename: "layout1.layout.html") }

      it do
        expect{ entity1.save! }.not_to raise_error
        expect{ entity2.save! }.to raise_error Mongoid::Errors::Validations
      end
    end
  end
end
