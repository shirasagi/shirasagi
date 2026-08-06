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
      let(:xss_link) { %(#" onclick="console.log('xss')" data-dummy=") }
      subject { build(:guide_procedure, cur_site: site, cur_node: node, link_url: xss_link) }

      it do
        expect(subject).to be_invalid
        expect(subject.errors[:link_url]).to have(1).items
        expect(subject.errors[:link_url]).to include(I18n.t("errors.messages.url"))
      end
    end
  end

  context "#to_liquid" do
    context "usual case" do
      let(:item1) { create(:guide_procedure, cur_site: site, cur_node: node, link_url: unique_url) }
      subject { item1.to_liquid }

      it do
        expect(subject.id).to eq item1.id
        expect(subject.name).to eq item1.name
        expect(subject.link_url).to eq item1.link_url
        expect(subject.link).to eq %(<a href="#{item1.link_url}">#{item1.name}</a>)
        expect(subject.html).to eq item1.html
        expect(subject.procedure_location).to eq item1.procedure_location
        expect(subject.belongings).to eq item1.belongings
        expect(subject.procedure_applicant).to eq item1.procedure_applicant
        expect(subject.remarks).to eq item1.remarks
      end
    end

    context "xss #1" do
      let(:xss_link) { "javascript:console.log('xss')" }
      let(:item1) do
        item = create(:guide_procedure, cur_site: site, cur_node: node)
        item.set(link_url: xss_link)
        item
      end
      subject { item1.to_liquid }

      it do
        expect(subject.id).to eq item1.id
        expect(subject.name).to eq item1.name
        expect(subject.link_url).to be_blank
        expect(subject.link).to eq item1.name
        expect(subject.html).to eq item1.html
        expect(subject.procedure_location).to eq item1.procedure_location
        expect(subject.belongings).to eq item1.belongings
        expect(subject.procedure_applicant).to eq item1.procedure_applicant
        expect(subject.remarks).to eq item1.remarks
      end
    end
  end
end
