require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let(:prefix) { I18n.t("workflow.cloned_name_prefix") }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "#new_clone" do
    context "with basic page" do
      let(:file1) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo1.png") }
      let(:file2) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo2.png") }
      let(:html) do
        [
          "<p>#{unique_id}</p>",
          "<p><a class=\"icon-png attachment\" href=\"#{file1.url}\">#{file1.humanized_name}</a></p>",
          "<p><a class=\"icon-png attachment\" href=\"#{file2.url}\">#{file2.humanized_name}</a></p>",
        ].join("\r\n\r\n")
      end
      let!(:item) do
        create :article_page, cur_site: site, cur_user: user, cur_node: node, html: html, file_ids: [ file1.id, file2.id ]
      end

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

          # 保存前は添付ファイルは元と同じ、HTML も元と同じ
          expect(subject.files.count).to eq 2
          expect(subject.files.pluck(:id)).to include(file1.id, file2.id)
          expect(subject.html).to include file1.url
          expect(subject.html).to include file2.url

          expect(SS::File.all.count).to eq 2
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

          expect(subject.released_type).to eq item.released_type
          expect(subject.created).to eq item.created
          expect(subject.updated).to be > item.updated
          expect(subject.released).to eq item.released
          expect(subject.first_released).to eq item.first_released

          # 複製の場合、添付ファイルは元のコピーなのでIDが異なるファイル（中身は同じ）し HTML も異なる
          expect(subject.files.count).to eq 2
          expect(subject.files.pluck(:id) & [ file1.id, file2.id ]).to be_blank
          expect(subject.files.pluck(:name)).to include(file1.name, file2.name)
          expect(subject.files.pluck(:filename)).to include(file1.filename, file2.filename)
          expect(subject.files.pluck(:content_type)).to include(file1.content_type, file2.content_type)
          expect(subject.files.pluck(:size)).to include(file1.size, file2.size)
          expect(subject.files.pluck(:state)).to include("closed", "closed")
          expect(subject.html).not_to include file1.url
          expect(subject.html).not_to include file2.url
          expect(subject.html).to include subject.files.first.url

          file1.reload
          expect(file1.owner_item_type).to eq item.class.name
          expect(file1.owner_item_id).to eq item.id
          expect(file1.state).to eq item.state
          expect(file1.state).not_to eq subject.state
          file2.reload
          expect(file2.owner_item_type).to eq item.class.name
          expect(file2.owner_item_id).to eq item.id
          expect(file2.state).to eq item.state
          expect(file2.state).not_to eq subject.state

          item.reload
          expect(item.files.count).to eq 2
          expect(item.files.pluck(:id)).to include(file1.id, file2.id)

          expect(SS::File.all.count).to eq 4
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

            expect(subject.released_type).to eq item.released_type
            expect(subject.created).to eq item.created
            expect(subject.updated).to be > item.updated
            expect(subject.released).to eq item.released
            expect(subject.first_released).to eq item.first_released

            # 差し替えページの場合、添付ファイルは元と同じ
            expect(subject.files.count).to eq 2
            expect(subject.files.pluck(:id)).to include(file1.id, file2.id)
            expect(subject.html).to include file1.url
            expect(subject.html).to include file2.url

            file1.reload
            expect(file1.owner_item_type).to eq item.class.name
            expect(file1.owner_item_id).to eq item.id
            expect(file1.state).to eq item.state
            expect(file1.state).not_to eq subject.state
            file2.reload
            expect(file2.owner_item_type).to eq item.class.name
            expect(file2.owner_item_id).to eq item.id
            expect(file2.state).to eq item.state
            expect(file1.state).not_to eq subject.state

            item.reload
            expect(item.master?).to be_truthy
            expect(item.branch?).to be_falsey
            expect(item.master_id).to be_blank
            expect(item.branches.count).to eq 1
            expect(item.branches.first.id).to eq subject.id

            subject.destroy
            expect { file1.reload }.not_to raise_error
            expect { file2.reload }.not_to raise_error
            item.reload
            expect(item.files.count).to eq 2
            expect(item.files.pluck(:id)).to include(file1.id, file2.id)
            expect(item.html).to include file1.url
            expect(item.html).to include file2.url

            expect(SS::File.all.count).to eq 2

            expect(History::Trash.all.count).to eq 1
            History::Trash.all.first.tap do |trash|
              expect(trash.site_id).to eq site.id
              expect(trash.version).to eq SS.version
              expect(trash.ref_coll).to eq subject.collection_name.to_s
              expect(trash.ref_class).to eq subject.class.name
              expect(trash.data).to be_present
              expect(trash.data["_id"]).to eq subject.id
              expect(trash.state).to be_blank
              expect(trash.action).to eq "save"
            end
          end
        end

        context "when branch was finally merged into its master" do
          let(:branch_name) { "name-#{unique_id}" }
          let(:branch_file) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "branch_logo.png") }
          let(:branch_html) do
            [
              "<p>#{unique_id}</p>",
              "<p><a class=\"icon-png attachment\" href=\"#{file1.url}\">#{file1.humanized_name}</a></p>",
              "<p><a class=\"icon-png attachment\" href=\"#{branch_file.url}\">#{branch_file.humanized_name}</a></p>",
            ].join("\r\n\r\n")
          end

          it do
            subject.class.find(subject.id).tap do |branch|
              expect(branch.new_clone?).to be_falsey
              expect(branch.master_id).to eq item.id
              expect(branch.state).to eq "closed"

              # merge into master
              branch.name = branch_name
              branch.html = branch_html
              branch.file_ids = [ file1.id, branch_file.id ]
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
            expect(item.files.count).to eq 2
            expect(item.files.pluck(:id)).to include(file1.id, branch_file.id)
            expect(item.html).to include file1.url
            expect(item.html).to include branch_file.url

            expect { file1.reload }.not_to raise_error
            expect(file1.owner_item_type).to eq item.class.name
            expect(file1.owner_item_id).to eq item.id
            expect { file2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
            expect { branch_file.reload }.not_to raise_error
            expect(branch_file.owner_item_type).to eq item.class.name
            expect(branch_file.owner_item_id).to eq item.id

            expect(SS::File.all.count).to eq 2

            expect(History::Trash.all.count).to eq 1
            History::Trash.all.first.tap do |trash|
              expect(trash.site_id).to eq site.id
              expect(trash.version).to eq SS.version
              expect(trash.ref_coll).to eq file2.collection_name.to_s
              expect(trash.ref_class).to eq file2.class.name
              expect(trash.data).to be_present
              expect(trash.data["_id"]).to eq file2.id
              expect(trash.state).to be_blank
              expect(trash.action).to eq "save"
            end
          end
        end
      end
    end
  end
end
