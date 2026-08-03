require 'spec_helper'

describe Guide::Procedure, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :guide_node_guide, cur_site: site }

  describe "#link_url" do
    context "xss #1" do
      let(:xss_link) { "javascript:console.log('xss')" }
      subject { build(:guide_procedure, cur_site: site, cur_node: node, link_url: xss_link) }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:link_url]).to have(1).items
        expect(subject.errors[:link_url]).to include(I18n.t("errors.messages.url"))
      end
    end

    context "xss #2" do
      let(:xss_link) { %Q(#" onclick="console.log('xss')" data-dummy=") }
      subject { build(:guide_procedure, cur_site: site, cur_node: node, link_url: xss_link) }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:link_url]).to have(1).items
        expect(subject.errors[:link_url]).to include(I18n.t("errors.messages.url"))
      end
    end
  end
end
