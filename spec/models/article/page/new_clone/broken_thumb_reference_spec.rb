require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let(:prefix) { I18n.t("workflow.cloned_name_prefix") }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "#new_clone" do
    context "with page having thumbnail" do
      let(:file) { tmp_ss_file(site: site, user: user, contents: file_path) }
      let!(:item) do
        create :article_page, cur_site: site, cur_user: user, cur_node: node, html: "<p>#{unique_id}</p>", thumb_id: file.id
      end

      before { file.destroy }

      context "before save" do
        subject { item.new_clone }

        it do
          expect(subject.persisted?).to be_falsey
          expect(subject.id).to eq 0
          expect(subject.site_id).to eq item.site_id
          expect(subject.name).to eq item.name
          expect(subject.index_name).to eq item.index_name
          expect(subject.filename).to eq "#{node.filename}/"
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
          expect(subject.new_clone?).to be_truthy
          expect(subject.master_id).to be_blank
          expect(subject.branches.count).to eq 0

          expect(subject.released_type).to eq item.released_type
          expect(subject.created).to eq item.created
          expect(subject.updated).to eq item.updated
          expect(subject.released).to eq item.released
          expect(subject.first_released).to eq item.first_released

          # 保存前はサムネイルは元と同じ
          expect(subject.thumb_id).to eq file.id
          expect(subject.thumb_id).to eq item.thumb_id
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
          expect(subject.filename).to end_with ".html"
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
          expect(subject.new_clone?).to be_truthy
          expect(subject.master_id).to be_blank
          expect(subject.branches.count).to eq 0

          # 複製の場合、公開日と初回公開日はクリアされる
          expect(subject.released_type).to eq item.released_type
          expect(subject.created).to eq item.created
          expect(subject.updated).to be > item.updated
          expect(subject.released).to eq item.released
          expect(subject.first_released).to eq item.first_released

          # サムネイルは削除されてしまっているのでコピーできないため blank となる
          expect(subject.thumb_id).to be_blank
        end
      end

      context "branch page" do
        subject do
          copy = item.new_clone
          copy.master = item
          copy.save!
          copy
        end

        context "when branch was finally destroyed" do
          it do
            expect(subject.persisted?).to be_truthy
            expect(subject.id).not_to eq item.id
            expect(subject.site_id).to eq item.site_id
            expect(subject.name).to eq item.name
            expect(subject.index_name).to eq item.index_name
            expect(subject.filename).not_to eq item.filename
            expect(subject.filename).to start_with "#{node.filename}/"
            expect(subject.filename).to end_with ".html"
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
            expect(subject.new_clone?).to be_truthy
            expect(subject.master_id).to eq item.id
            expect(subject.branches.count).to eq 0

            # 差し替えページの場合、公開日と初回公開日は元と同じ
            expect(subject.released_type).to eq item.released_type
            expect(subject.created).to eq item.created
            expect(subject.updated).to be > item.updated
            expect(subject.released).to eq item.released
            expect(subject.first_released).to eq item.first_released

            # サムネイルは削除されてしまっているのでコピーできないため blank となる
            expect(subject.thumb_id).to be_blank

            subject.destroy
            item.reload
            expect(item.thumb_id).to eq file.id
            # サムネイルは削除されてしまっているので blank となる
            expect(item.thumb).to be_blank
          end
        end

        context "when branch was finally merged into its master" do
          it do
            subject.class.find(subject.id).tap do |branch|
              expect(branch.new_clone?).to be_falsey
              expect(branch.master_id).to eq item.id
              expect(branch.state).to eq "closed"

              # merge into master
              branch.state = "public"
              branch.save

              branch.file_ids = nil
              branch.skip_history_trash = true
              branch.destroy
            end

            item.reload
            expect(item.master?).to be_truthy
            expect(item.branch?).to be_falsey
            expect(item.master_id).to be_blank
            expect(item.branches.count).to eq 0
            # サムネイルは削除されてしまっているので、マージすると blank となる
            expect(item.thumb_id).to be_blank
            expect(item.thumb).to be_blank
          end
        end
      end
    end
  end
end
