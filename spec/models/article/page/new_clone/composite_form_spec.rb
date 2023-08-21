require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let(:prefix) { I18n.t("workflow.cloned_name_prefix") }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "#new_clone" do
    context "with page having composite columns" do
      let!(:file1) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo1.png") }
      let!(:file2) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo2.png") }
      let!(:file3) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo3.png") }
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
      end
      let!(:column2) do
        create(:cms_column_free, cur_site: site, cur_form: form, order: 2)
      end
      let!(:item) { create :article_page, cur_site: site, cur_user: user, cur_node: node, form: form }

      before do
        html = [
          "<p>#{unique_id}</p>",
          "<p><a class=\"icon-png attachment\" href=\"#{file2.url}\">#{file2.humanized_name}</a></p>",
          "<p><a class=\"icon-png attachment\" href=\"#{file3.url}\">#{file3.humanized_name}</a></p>",
        ].join("\r\n\r\n")

        item.column_values = [
          column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
          column2.value_type.new(column: column2, value: html, file_ids: [ file2.id, file3.id ])
        ]
        item.save!

        file1.reload
        expect(file1.owner_item_type).to eq item.class.name
        expect(file1.owner_item_id).to eq item.id
        file2.reload
        expect(file2.owner_item_type).to eq item.class.name
        expect(file2.owner_item_id).to eq item.id
        file3.reload
        expect(file3.owner_item_type).to eq item.class.name
        expect(file3.owner_item_id).to eq item.id
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

          # 保存前は元と同じ column_value
          expect(subject.column_values.count).to eq 0
          expect(subject.column_values.length).to eq 2
          expect(subject.column_values.length).to eq item.column_values.count

          subject.column_values[0].tap do |subject_column_value1|
            item.column_values[0].tap do |item_column_value1|
              expect(subject_column_value1.class).to eq item_column_value1.class
              expect(subject_column_value1.file_id).to eq item_column_value1.file_id
              expect(subject_column_value1.file_label).to eq item_column_value1.file_label
            end
          end
          subject.column_values[1].tap do |subject_column_value2|
            item.column_values[1].tap do |item_column_value2|
              expect(subject_column_value2.class).to eq item_column_value2.class
              expect(subject_column_value2.value).to eq item_column_value2.value
              expect(subject_column_value2.file_ids).to eq item_column_value2.file_ids
            end
          end

          expect(SS::File.all.count).to eq 3
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

          # 複製の場合、添付ファイルは元のコピーなのでIDが異なるファイル（中身は同じ）し HTML も異なる
          expect(subject.column_values.count).to eq 2
          expect(subject.column_values.count).to eq item.column_values.count

          subject.column_values[0].tap do |subject_column_value1|
            item.column_values[0].tap do |item_column_value1|
              expect(subject_column_value1.class).to eq item_column_value1.class
              expect(subject_column_value1.file_id).not_to eq item_column_value1.file_id
              expect(subject_column_value1.file_label).to eq item_column_value1.file_label
            end
          end
          subject.column_values[1].tap do |subject_column_value2|
            item.column_values[1].tap do |item_column_value2|
              expect(subject_column_value2.class).to eq item_column_value2.class
              expect(subject_column_value2.file_ids & item_column_value2.file_ids).to be_blank
              expect(subject_column_value2.value).not_to include file2.url
              expect(subject_column_value2.value).to include subject_column_value2.files.first.url
            end
          end

          # 元ファイルの所有者は元のまま
          file1.reload
          expect(file1.owner_item_type).to eq item.class.name
          expect(file1.owner_item_id).to eq item.id
          file2.reload
          expect(file2.owner_item_type).to eq item.class.name
          expect(file2.owner_item_id).to eq item.id
          file3.reload
          expect(file3.owner_item_type).to eq item.class.name
          expect(file3.owner_item_id).to eq item.id

          item.reload
          item.column_values[0].tap do |item_column_value1|
            expect(item_column_value1.file_id).to eq file1.id
          end
          item.column_values[1].tap do |item_column_value2|
            expect(item_column_value2.file_ids).to eq [ file2.id, file3.id ]
            expect(item_column_value2.value).to include file2.url
            expect(item_column_value2.value).to include file3.url
          end

          expect(SS::File.all.count).to eq 6
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
            expect(subject.master_id).to eq item.id
            expect(subject.branches.count).to eq 0

            # 差し替えページの場合、公開日と初回公開日は元と同じ
            expect(subject.released_type).to eq item.released_type
            expect(subject.created).to eq item.created
            expect(subject.updated).to be > item.updated
            expect(subject.released).to eq item.released
            expect(subject.first_released).to eq item.first_released

            # 差し替えページの場合、添付ファイルは元と同じ
            expect(subject.column_values.count).to eq 2
            expect(subject.column_values.count).to eq item.column_values.count

            subject.column_values[0].tap do |subject_column_value1|
              item.column_values[0].tap do |item_column_value1|
                expect(subject_column_value1.class).to eq item_column_value1.class
                expect(subject_column_value1.file_id).to eq item_column_value1.file_id
                expect(subject_column_value1.file_label).to eq item_column_value1.file_label
              end
            end
            subject.column_values[1].tap do |subject_column_value2|
              item.column_values[1].tap do |item_column_value2|
                expect(subject_column_value2.class).to eq item_column_value2.class
                expect(subject_column_value2.file_ids).to eq item_column_value2.file_ids
                expect(subject_column_value2.value).to eq item_column_value2.value
              end
            end

            # ファイルの所有者は元のまま
            file1.reload
            expect(file1.owner_item_type).to eq item.class.name
            expect(file1.owner_item_id).to eq item.id
            file2.reload
            expect(file2.owner_item_type).to eq item.class.name
            expect(file2.owner_item_id).to eq item.id
            file3.reload
            expect(file3.owner_item_type).to eq item.class.name
            expect(file3.owner_item_id).to eq item.id

            item.reload
            expect(item.master?).to be_truthy
            expect(item.branch?).to be_falsey
            expect(item.master_id).to be_blank
            expect(item.branches.count).to eq 1
            expect(item.branches.first.id).to eq subject.id

            subject.destroy
            expect { file1.reload }.not_to raise_error
            expect { file2.reload }.not_to raise_error
            expect { file3.reload }.not_to raise_error
            item.reload
            item.column_values[0].tap do |item_column_value1|
              expect(item_column_value1.file_id).to eq file1.id
            end
            item.column_values[1].tap do |item_column_value2|
              expect(item_column_value2.file_ids).to eq [ file2.id, file3.id ]
              expect(item_column_value2.value).to include file2.url
              expect(item_column_value2.value).to include file3.url
            end

            expect(SS::File.all.count).to eq 3

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
              "<p><a class=\"icon-png attachment\" href=\"#{file2.url}\">#{file2.humanized_name}</a></p>",
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
              # branch.html = branch_html
              # branch.file_ids = [ file2.id, branch_file.id ]
              branch.column_values = [
                column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
                column2.value_type.new(column: column2, value: branch_html, file_ids: [ file2.id, branch_file.id ])
              ]
              branch.state = "public"
              branch.save

              branch.file_ids = nil
              branch.skip_history_trash = true
              branch.destroy
            end

            expect { file1.reload }.not_to raise_error
            expect { file2.reload }.not_to raise_error
            expect { file3.reload }.to raise_error Mongoid::Errors::DocumentNotFound
            expect { branch_file.reload }.not_to raise_error
            item.reload
            expect(item.master?).to be_truthy
            expect(item.branch?).to be_falsey
            expect(item.master_id).to be_blank
            expect(item.branches.count).to eq 0
            item.column_values[0].tap do |item_column_value1|
              expect(item_column_value1.file_id).to eq file1.id
            end
            item.column_values[1].tap do |item_column_value2|
              expect(item_column_value2.file_ids).to have(2).items
              expect(item_column_value2.file_ids).to include(file2.id, branch_file.id)
              expect(item_column_value2.value).to include file2.url
              expect(item_column_value2.value).to include branch_file.url
            end

            expect(SS::File.all.count).to eq 3

            expect(History::Trash.all.count).to eq 1
            History::Trash.all.first.tap do |trash|
              expect(trash.site_id).to eq site.id
              expect(trash.version).to eq SS.version
              expect(trash.ref_coll).to eq file3.collection_name.to_s
              expect(trash.ref_class).to eq file3.class.name
              expect(trash.data).to be_present
              expect(trash.data["_id"]).to eq file3.id
              expect(trash.state).to be_blank
              expect(trash.action).to eq "save"
            end
          end
        end
      end
    end
  end
end
