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
          expect(subject.new_clone?).to be_truthy
          expect(subject.master_id).to be_blank
          expect(subject.branches.count).to eq 0

          expect(subject.released_type).to eq item.released_type
          expect(subject.created).to eq item.created
          expect(subject.updated).to eq item.updated
          expect(subject.released).to eq item.released
          expect(subject.first_released).to eq item.first_released

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
          expect(subject.new_clone?).to be_truthy
          expect(subject.master_id).to be_blank
          expect(subject.branches.count).to eq 0

          expect(subject.released_type).to eq item.released_type
          expect(subject.created).to eq item.created
          expect(subject.updated).to be > item.updated
          expect(subject.released).to eq item.released
          expect(subject.first_released).to eq item.first_released

          # 複製の場合、添付ファイルは元のコピーなのでIDが異なるファイル（中身は同じ）し HTML も異なる
          expect(subject.files.count).to eq 1
          subject.files.first.tap do |subject_file|
            expect(subject_file.id).not_to eq file.id
            expect(subject_file.name).to eq file.name
            expect(subject_file.filename).to eq file.filename
            expect(subject_file.content_type).to eq file.content_type
            expect(subject_file.size).to eq file.size
          end
          expect(subject.html).not_to include file.url
          expect(subject.html).to include subject.files.first.url

          file.reload
          expect(file.owner_item_type).to eq item.class.name
          expect(file.owner_item_id).to eq item.id

          item.reload
          expect(item.files.count).to eq 1
          expect(item.files.first.id).to eq file.id
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

            expect(subject.released_type).to eq item.released_type
            expect(subject.created).to eq item.created
            expect(subject.updated).to be > item.updated
            expect(subject.released).to eq item.released
            expect(subject.first_released).to eq item.first_released

            # 差し替えページの場合、添付ファイルは元と同じ
            expect(subject.files.count).to eq 1
            expect(subject.files.first.id).to eq file.id
            expect(subject.html).to include file.url

            file.reload
            expect(file.owner_item_type).to eq item.class.name
            expect(file.owner_item_id).to eq item.id

            item.reload
            expect(item.master?).to be_truthy
            expect(item.branch?).to be_falsey
            expect(item.master_id).to be_blank
            expect(item.branches.count).to eq 1
            expect(item.branches.first.id).to eq subject.id

            subject.destroy
            expect { file.reload }.not_to raise_error
            item.reload
            expect(item.files.count).to eq 1
            expect(item.files.first.id).to eq file.id
            expect(item.html).to include file.url
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
              branch.destroy
            end

            expect { file.reload }.not_to raise_error
            item.reload
            expect(item.master?).to be_truthy
            expect(item.branch?).to be_falsey
            expect(item.master_id).to be_blank
            expect(item.branches.count).to eq 0
            expect(item.files.count).to eq 1
            expect(item.files.first.id).to eq file.id
            expect(item.html).to include file.url
          end
        end
      end
    end
  end
end
