require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page }
  let(:user1) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
  let(:user2) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }

  context "with regular page" do
    let(:file) do
      filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
      basename = ::File.basename(filename)
      SS::File.create_empty!(
        site_id: site.id, cur_user: cms_user, name: basename, filename: basename,
        content_type: "image/png", model: 'ss/temp_file'
      ) do |file|
        ::FileUtils.cp(filename, file.path)
      end
    end

    let!(:master_page) { create(:article_page, cur_site: site, cur_node: node, cur_user: cms_user) }
    let!(:branch_page) do
      master_page.cur_node = node

      copy = master_page.new_clone
      copy.master = master_page
      copy.save!
      master_page.reload

      copy.html = "#{copy.html}\n<img src=\"#{file.url}\" alt=\"#{file.humanized_name}\">"
      copy.file_ids = Array(copy.file_ids) + [ file.id ]
      copy.save!
      file.reload

      copy
    end

    context "when branch page merges into master page" do
      before { login_user user1 }

      context "without edit lock" do
        it do
          visit article_page_path(site, node, branch_page)
          expect(page).to have_css("#addon-workflow-agents-addons-branch table.branches", text: master_page.name)

          click_on I18n.t("ss.links.edit")
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          # branch page is destroyed after merge
          expect(Cms::Page.where(id: branch_page.id)).to be_blank

          # there are no pages in trash
          expect(History::Trash.all.count).to eq 0

          # master page has `file`
          master_page.reload
          expect(master_page.file_ids).to eq branch_page.file_ids
          expect(master_page.files).to have(1).items
          expect(master_page.html).to include(master_page.files.first.url)

          expect(master_page.files.first.owner_item_id).to eq master_page.id
        end
      end

      context "with edit lock by other user" do
        before { master_page.acquire_lock(user: user2) }

        it do
          visit article_page_path(site, node, master_page)
          within "#addon-cms-agents-addons-edit_lock" do
            expect(page).to have_content(I18n.t("errors.messages.locked", user: user2.long_name))
          end
          expect(page).to have_css("#addon-workflow-agents-addons-branch table.branches", text: branch_page.name)

          visit article_page_path(site, node, branch_page)
          expect(page).to have_css("#addon-workflow-agents-addons-branch table.branches", text: master_page.name)

          click_on I18n.t("ss.links.edit")
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css("#errorExplanation", text: I18n.t("errors.messages.locked", user: user2.long_name))

          # branch page is still remaining
          expect(Cms::Page.where(id: branch_page.id)).to be_present

          # master page is not modified
          master_page.reload
          expect(master_page.html).to be_blank
          expect(master_page.files).to be_blank
        end
      end
    end
  end

  context "with form page" do
    let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }

    let!(:form_column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text', order: 10)
    end
    let!(:form_column2) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: 'image', order: 20)
    end
    let!(:form_column3) do
      create(:cms_column_free, cur_site: site, cur_form: form, order: 30)
    end

    let(:file1) do
      filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
      basename = ::File.basename(filename)
      SS::File.create_empty!(
        site_id: site.id, cur_user: cms_user, name: basename, filename: basename,
        content_type: "image/png", model: 'ss/temp_file'
      ) do |file|
        ::FileUtils.cp(filename, file.path)
      end
    end
    let(:file2) do
      filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
      basename = ::File.basename(filename)
      SS::File.create_empty!(
        site_id: site.id, cur_user: cms_user, name: basename, filename: basename,
        content_type: "image/png", model: 'ss/temp_file'
      ) do |file|
        ::FileUtils.cp(filename, file.path)
      end
    end
    let(:file2_img_tag) { "<img src=\"#{file2.url}\" alt=\"#{file2.humanized_name}\">" }

    let!(:master_page) { create(:article_page, cur_site: site, cur_node: node, cur_user: cms_user, form: form) }
    let!(:branch_page) do
      master_page.cur_node = node

      copy = master_page.new_clone
      copy.master = master_page
      copy.save!
      master_page.reload

      copy.column_values = [
        form_column1.value_type.new(column: form_column1, value: unique_id * 6),
        form_column2.value_type.new(column: form_column2, file_id: file1.id, file_label: file1.humanized_name),
        form_column3.value_type.new(
          column: form_column3, value: unique_id * 5 + "\n" + file2_img_tag, file_ids: [ file2.id ]
        )
      ]
      copy.save!

      copy
    end

    context "when branch page merges into master page" do
      before { login_user user1 }

      context "without edit lock" do
        it do
          visit article_page_path(site, node, branch_page)
          expect(page).to have_css("#addon-workflow-agents-addons-branch table.branches", text: master_page.name)

          click_on I18n.t("ss.links.edit")
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          # master page has `file`
          master_page.reload
          expect(master_page.column_values).to have(3).items
          master_page.column_values.order_by(order: 1).to_a.tap do |column_values|
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::TextField)
            end
            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::FileUpload)
              expect(column_value.file).to be_present
            end
            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::Free)
              expect(column_value.files).to have(1).items
            end
          end

          # branch page is destroyed after merge
          expect(Cms::Page.where(id: branch_page.id)).to be_blank
          expect(branch_page.column_values).to have(3).items
          branch_page.column_values.order_by(order: 1).to_a.tap do |column_values|
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::TextField)
            end
            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::FileUpload)
              # expect(column_value.file).to be_blank
              expect(SS::File.where(id: column_value.file_id)).to be_blank
            end
            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::Free)
              expect(column_value.files).to have(0).items
            end
          end

          # there are no pages in trash
          expect(History::Trash.all.count).to eq 0
        end
      end

      context "with edit lock by other user" do
        before { master_page.acquire_lock(user: user2) }

        it do
          visit article_page_path(site, node, master_page)
          within "#addon-cms-agents-addons-edit_lock" do
            expect(page).to have_content(I18n.t("errors.messages.locked", user: user2.long_name))
          end
          expect(page).to have_css("#addon-workflow-agents-addons-branch table.branches", text: branch_page.name)

          visit article_page_path(site, node, branch_page)
          expect(page).to have_css("#addon-workflow-agents-addons-branch table.branches", text: master_page.name)

          click_on I18n.t("ss.links.edit")
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css("#errorExplanation", text: I18n.t("errors.messages.locked", user: user2.long_name))

          # branch page is still remaining
          expect(Cms::Page.where(id: branch_page.id)).to be_present

          # master page is not modified
          master_page.reload
          expect(master_page.column_values).to be_blank
        end
      end
    end
  end
end
