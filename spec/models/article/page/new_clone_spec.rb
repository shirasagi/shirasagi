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

    context "with page having thumbnail" do
      let(:file) { tmp_ss_file(site: site, user: user, contents: file_path) }
      let!(:item) do
        create :article_page, cur_site: site, cur_user: user, cur_node: node, html: "<p>#{unique_id}</p>", thumb_id: file.id
      end

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

          # 保存前はサムネイルは元と同じ
          expect(subject.thumb_id).to eq file.id
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

          expect(subject.thumb_id).not_to eq file.id
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

          expect(subject.thumb_id).not_to eq file.id

          item.reload
          expect(item.master?).to be_truthy
          expect(item.branch?).to be_falsey
          expect(item.master_id).to be_blank
          expect(item.branches.count).to eq 1
          expect(item.branches.first.id).to eq subject.id
        end
      end
    end

    context "with page having composite columns" do
      let!(:file1) { tmp_ss_file(site: site, user: user, contents: file_path) }
      let!(:file2) { tmp_ss_file(site: site, user: user, contents: file_path) }
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
          "<p><a class=\"icon-png attachment\" href=\"#{file2.url}\">#{file2.humanized_name}</a></p>"
        ].join("\r\n\r\n")

        item.column_values = [
          column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
          column2.value_type.new(column: column2, value: html, file_ids: [ file2.id ])
        ]
        item.save!
      end

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
