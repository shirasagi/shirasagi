require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let!(:item) { create :article_page, cur_site: site, cur_user: user, cur_node: node }
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "on_copy: :clear" do
    context "with Workflow::Approver" do
      let(:workflow_user_id) { rand(101..110) }
      let(:workflow_agent_id) { rand(111..120) }
      let(:workflow_state) { "request" }
      let(:workflow_comment) { unique_id }
      let(:workflow_pull_up) { unique_id }
      let(:workflow_on_remand) { unique_id }
      let(:workflow_approvers) { [{ level: 1, user_id: rand(121..130), state: "pending", comment: "" }] }
      let(:workflow_required_counts) { [ false ] }
      let(:workflow_approver_attachment_uses) { [ false ] }
      let(:workflow_current_circulation_level) { rand(1..10) }
      let(:workflow_circulations) { [{ level: 1, user_id: rand(131..140), state: "pending", comment: "" }] }
      let(:workflow_circulation_attachment_uses) { [ false ] }
      let(:approved) { now - rand(7..10).days }
      let(:branch_name) { "name-#{unique_id}" }
      let(:branch_workflow_user_id) { rand(201..210) }
      let(:branch_workflow_agent_id) { rand(211..220) }
      let(:branch_workflow_comment) { unique_id }
      let(:branch_workflow_approvers) { [{ level: 1, user_id: rand(221..230), state: "approved", comment: unique_id }] }
      let(:branch_workflow_required_counts) { [ 1 ] }
      let(:branch_approved) { approved + 3.days }

      before do
        item.update!(
          workflow_user_id: workflow_user_id, workflow_agent_id: workflow_agent_id, workflow_state: workflow_state,
          workflow_comment: workflow_comment, workflow_pull_up: workflow_pull_up, workflow_on_remand: workflow_on_remand,
          workflow_approvers: workflow_approvers, workflow_required_counts: workflow_required_counts,
          workflow_approver_attachment_uses: workflow_approver_attachment_uses,
          workflow_current_circulation_level: workflow_current_circulation_level, workflow_circulations: workflow_circulations,
          workflow_circulation_attachment_uses: workflow_circulation_attachment_uses, approved: approved
        )
      end

      context "#new_clone" do
        it do
          item.reload
          expect(item.workflow_user_id).to eq workflow_user_id
          expect(item.workflow_agent_id).to eq workflow_agent_id
          expect(item.workflow_state).to eq workflow_state
          expect(item.workflow_comment).to eq workflow_comment
          expect(item.workflow_pull_up).to eq workflow_pull_up
          expect(item.workflow_on_remand).to eq workflow_on_remand
          expect(item.workflow_approvers).to eq workflow_approvers
          expect(item.workflow_required_counts).to eq workflow_required_counts
          expect(item.workflow_approver_attachment_uses).to eq workflow_approver_attachment_uses
          expect(item.workflow_current_circulation_level).to eq workflow_current_circulation_level
          expect(item.workflow_circulations).to eq workflow_circulations
          expect(item.workflow_circulation_attachment_uses).to eq workflow_circulation_attachment_uses
          expect(item.approved).to eq approved

          branch = item.new_clone
          expect(branch.workflow_user_id).to be_blank
          expect(branch.workflow_agent_id).to be_blank
          expect(branch.workflow_state).to be_blank
          expect(branch.workflow_comment).to be_blank
          expect(branch.workflow_pull_up).to be_blank
          expect(branch.workflow_on_remand).to be_blank
          expect(branch.workflow_approvers).to be_blank
          expect(branch.workflow_required_counts).to be_blank
          expect(branch.workflow_approver_attachment_uses).to be_blank
          expect(branch.workflow_current_circulation_level).to eq 0
          expect(branch.workflow_circulations).to be_blank
          expect(branch.workflow_circulation_attachment_uses).to be_blank
          expect(branch.approved).to be_blank

          branch.master = item
          branch.save!
          expect(branch.workflow_user_id).to be_blank
          expect(branch.workflow_agent_id).to be_blank
          expect(branch.workflow_state).to be_blank
          expect(branch.workflow_comment).to be_blank
          expect(branch.workflow_pull_up).to be_blank
          expect(branch.workflow_on_remand).to be_blank
          expect(branch.workflow_approvers).to be_blank
          expect(branch.workflow_required_counts).to be_blank
          expect(branch.workflow_approver_attachment_uses).to be_blank
          expect(branch.workflow_current_circulation_level).to eq 0
          expect(branch.workflow_circulations).to be_blank
          expect(branch.workflow_circulation_attachment_uses).to be_blank
          expect(branch.approved).to be_blank

          # merge
          branch.class.find(branch.id).tap do |branch|
            branch.name = branch_name
            branch.state = "public"
            branch.workflow_user_id = branch_workflow_user_id
            branch.workflow_agent_id = branch_workflow_agent_id
            branch.workflow_state = "approved"
            branch.workflow_comment = branch_workflow_comment
            branch.workflow_approvers = branch_workflow_approvers
            branch.workflow_required_counts = branch_workflow_required_counts
            branch.approved = branch_approved
            branch.save!
            branch.destroy
          end

          item.reload
          expect(item.workflow_user_id).to eq branch_workflow_user_id
          expect(item.workflow_agent_id).to eq branch_workflow_agent_id
          expect(item.workflow_state).to eq "approved"
          expect(item.workflow_comment).to eq branch_workflow_comment
          expect(item.workflow_pull_up).to be_blank
          expect(item.workflow_on_remand).to be_blank
          expect(item.workflow_approvers).to eq branch_workflow_approvers
          expect(item.workflow_required_counts).to eq branch_workflow_required_counts
          expect(item.workflow_approver_attachment_uses).to be_blank
          expect(item.workflow_current_circulation_level).to eq 0
          expect(item.workflow_circulations).to be_blank
          expect(item.workflow_circulation_attachment_uses).to be_blank
          expect(item.approved).to eq branch_approved
        end
      end

      context "with sys/site_copy_job" do
        let!(:task) { Sys::SiteCopyTask.new }
        let(:target_host_name) { unique_id }
        let(:target_host_host) { unique_id }
        let(:target_host_domain) { "#{unique_id}.example.jp" }

        before do
          task.target_host_name = target_host_name
          task.target_host_host = target_host_host
          task.target_host_domains = [ target_host_domain ]
          task.source_site_id = site.id
          task.copy_contents = "pages"
          task.save!
        end

        it do
          expect { Sys::SiteCopyJob.perform_now }.to output(include(item.filename)).to_stdout

          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          target_site = Cms::Site.find_by(name: target_host_name)
          expect(Article::Page.site(target_site).count).to eq 1
          copy = Article::Page.site(target_site).first
          expect(copy.name).to eq item.name
          expect(copy.workflow_user_id).to be_blank
          expect(copy.workflow_agent_id).to be_blank
          expect(copy.workflow_state).to be_blank
          expect(copy.workflow_comment).to be_blank
          expect(copy.workflow_pull_up).to be_blank
          expect(copy.workflow_on_remand).to be_blank
          expect(copy.workflow_approvers).to be_blank
          expect(copy.workflow_required_counts).to be_blank
          expect(copy.workflow_approver_attachment_uses).to be_blank
          expect(copy.workflow_current_circulation_level).to eq 0
          expect(copy.workflow_circulations).to be_blank
          expect(copy.workflow_circulation_attachment_uses).to be_blank
          expect(copy.approved).to be_blank
        end
      end
    end
  end
end
