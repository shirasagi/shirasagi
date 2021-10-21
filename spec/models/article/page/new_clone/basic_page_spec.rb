require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let(:prefix) { I18n.t("workflow.cloned_name_prefix") }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "#new_clone" do
    context "with basic page" do
      let(:file) { tmp_ss_file(site: site, user: user, contents: file_path) }
      let(:html) do
        [
          "<p>#{unique_id}</p>",
          "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
        ].join("\r\n\r\n")
      end
      let!(:item) { create :article_page, cur_site: site, cur_user: user, cur_node: node, html: html, file_ids: [ file.id ] }

      context "before save" do
        subject { item.new_clone }

        it do
          expect(subject.persisted?).to be_falsey
          expect(subject.id).to eq 0
          expect(subject.site_id).to eq item.site_id
          expect(subject.name).to eq item.name
          expect(subject.index_name).to eq item.index_name
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
          expect(subject.master?).to be_truthy
          expect(subject.branch?).to be_falsey
          expect(subject.master_id).to be_blank
          expect(subject.branches.count).to eq 0

          # 保存前は添付ファイルは元と同じ、HTML も元と同じ
          expect(subject.files.count).to eq 1
          expect(subject.files.first.id).to eq file.id
          expect(subject.html).to include file.url
        end
      end

      context "copy page" do
        subject do
          copy = item.new_clone
          copy.name = "[#{prefix}] #{copy.name}"
          copy.save!
          copy
        end

        it do
          expect(subject.persisted?).to be_truthy
          expect(subject.id).not_to eq item.id
          expect(subject.site_id).to eq item.site_id
          expect(subject.name).to eq "[#{prefix}] #{item.name}"
          expect(subject.index_name).to eq item.index_name
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
          expect(subject.master?).to be_truthy
          expect(subject.branch?).to be_falsey
          expect(subject.master_id).to be_blank
          expect(subject.branches.count).to eq 0

          expect(subject.files.count).to eq 1
          expect(subject.files.first.id).not_to eq file.id
          expect(subject.html).not_to include file.url
          expect(subject.html).to include subject.files.first.url
        end
      end

      context "branch page" do
        subject do
          copy = item.new_clone
          copy.master = item
          copy.save!
          copy
        end

        it do
          expect(subject.persisted?).to be_truthy
          expect(subject.id).not_to eq item.id
          expect(subject.site_id).to eq item.site_id
          expect(subject.name).to eq item.name
          expect(subject.index_name).to eq item.index_name
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
          expect(subject.master?).to be_falsey
          expect(subject.branch?).to be_truthy
          expect(subject.master_id).to eq item.id
          expect(subject.branches.count).to eq 0

          expect(subject.files.count).to eq 1
          expect(subject.files.first.id).not_to eq file.id
          expect(subject.html).not_to include file.url
          expect(subject.html).to include subject.files.first.url

          item.reload
          expect(item.master?).to be_truthy
          expect(item.branch?).to be_falsey
          expect(item.master_id).to be_blank
          expect(item.branches.count).to eq 1
          expect(item.branches.first.id).to eq subject.id
        end
      end
    end
  end
end
