require 'spec_helper'

describe SS::Site do
  subject(:model) { SS::Site }
  subject(:factory) { :ss_site }

  it_behaves_like "mongoid#save", presence: %w[name host]
  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }

    it { expect(item.domain).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
  end
end
