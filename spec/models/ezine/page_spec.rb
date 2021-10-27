require 'spec_helper'

RSpec.describe Ezine::Page, type: :model, dbscope: :example do
  describe "#attributes" do
    let(:node) { create :ezine_node_page }
    let(:item) { create :ezine_page, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.ezine_page_path(site: item.site, cid: node.id, id: item.id) }

    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
  end

  describe "#members_to_deliver" do
    subject { page.members_to_deliver }
    let!(:node) { create :ezine_node_page }

    context "completed flag is true" do
      let(:page) { create :ezine_page, cur_site: node.site, cur_node: node, completed: true }

      it { is_expected.to be_empty }
    end

    context "completed flag is false" do
      let!(:page) { create :ezine_page, cur_site: node.site, cur_node: node }
      let!(:member) { create :ezine_member, node: node }

      context "delivered to all members" do
        before do
          Ezine::SentLog.create(
            node_id: node.id, page_id: page.id, email: member.email
          )
        end

        it { is_expected.to be_empty }
      end

      context "a member not delivered to exists" do
        it { is_expected.to include member }

        context "but that member's state is disabled" do
          before { member.update state: "disabled" }

          it { is_expected.to be_empty }
        end
      end
    end
  end
end
