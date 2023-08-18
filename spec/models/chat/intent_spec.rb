require 'spec_helper'

describe Chat::Intent do
  subject(:model) { described_class }
  subject(:factory) { :chat_intent }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }

    it { expect(item.name).to be_truthy }
    it { expect(item.phrase).to be_truthy }
    it { expect(item.duplicate?).to be_falsey }
    it { expect(described_class.intents(item.name)).to be_truthy }
    it { expect(described_class.intents(item.phrase.first)).to be_truthy }
    it { expect(described_class.intents('')).to be_nil }
    it { expect(described_class.find_intent(item.name)).to be_truthy }
    it { expect(described_class.find_intent(item.phrase.first)).to be_truthy }
    it { expect(described_class.find_intent('')).to be_nil }
    it { expect(described_class.response(item.name)).to eq item.response }
    it { expect(described_class.response(item.phrase.first)).to eq item.response }
    it { expect(described_class.response('')).to be_nil }
  end
end
