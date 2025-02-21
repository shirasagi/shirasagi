require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:master_page) { create :article_page, cur_site: site, cur_node: node }
  let!(:branch_page) do
    branch_page = master_page.new_clone
    branch_page.master = master_page
    branch_page.save!
    branch_page
  end
  subject { branch_page.new_clone }

  it do
    expect(subject.persisted?).to be_falsey
    expect(subject.id).to eq 0
    expect(subject.site_id).to eq branch_page.site_id
    expect(subject.name).to eq branch_page.name
    expect(subject.index_name).to eq branch_page.index_name
    expect(subject.filename).to eq "#{node.filename}/"
    expect(subject.depth).to eq branch_page.depth
    expect(subject.order).to eq branch_page.order
    expect(subject.state).to eq 'closed'
    expect(subject.group_ids).to eq branch_page.group_ids
    expect(subject.workflow_user_id).to be_nil
    expect(subject.workflow_state).to be_nil
    expect(subject.workflow_comment).to be_nil
    expect(subject.workflow_approvers).to eq []
    expect(subject.workflow_required_counts).to eq []
    expect(subject.lock_owner_id).to be_nil
    expect(subject.lock_until).to be_nil
    expect(subject.master?).to be_truthy
    expect(subject.branch?).to be_falsey
    expect(subject.new_clone?).to be_truthy
    expect(subject.master_id).to be_blank
    expect(subject.branches.count).to eq 0
  end
end
