require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :article_node_page, cur_site: site }

  describe "#new_clone" do
    context "with simple page" do
      let(:item) { create :article_page, cur_site: site, cur_node: node, html: "   <p>あ。&rarr;い</p>\r\n   " }
      subject { item.new_clone }

      it do
        expect(subject.new_record?).to be_truthy
        expect(subject.site_id).to eq item.site_id
        expect(subject.name).to eq item.name
        expect(subject.filename).not_to eq item.filename
        expect(subject.filename).to start_with "#{node.filename}/"
        expect(subject.depth).to eq item.depth
        expect(subject.order).to eq item.order
        expect(subject.state).not_to eq item.state
        expect(subject.state).to eq 'closed'
        expect(subject.group_ids).to eq item.group_ids
        expect(subject.permission_level).to eq item.permission_level
        expect(subject.workflow_user_id).to be_nil
        expect(subject.workflow_state).to be_nil
        expect(subject.workflow_comment).to be_nil
        expect(subject.workflow_approvers).to eq []
        expect(subject.workflow_required_counts).to eq []
        expect(subject.lock_owner_id).to be_nil
        expect(subject.lock_until).to be_nil
      end
    end
  end
end
