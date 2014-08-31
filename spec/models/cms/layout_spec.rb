require 'spec_helper'

describe Cms::Layout do
  subject(:model) { Cms::Layout }
  subject(:factory) { :cms_layout }
  
  it_behaves_like "mongoid#save", presence: %w[name state filename]
  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
  
  describe "#attributes" do
    subject(:item) { model.first }
    
    it { expect(item.render_html).not_to eq nil }
    it { expect(item.render_json).not_to eq nil }
    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.json_path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.json_path).not_to eq nil }
    it { expect(item.public?).not_to eq nil }
    it { expect(item.node).to eq nil }
    it { expect(item.state_options).not_to eq nil }
  end
end
