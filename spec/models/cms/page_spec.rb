require 'spec_helper'

describe Cms::Page do
  subject(:model) { Cms::Page }
  subject(:factory) { :cms_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }

    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.public?).not_to eq nil }
    it { expect(item.parent).to eq false }
  end

  describe "#becomes_with_route" do
    subject { create(:cms_page, route: "article/page") }
    it { expect(subject.becomes_with_route).to be_kind_of(Article::Page) }
  end
end
