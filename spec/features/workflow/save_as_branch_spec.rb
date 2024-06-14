require 'spec_helper'

describe "close_confirmation", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }

  let!(:permissions) do
    Cms::Role.permission_names.select { |item| item =~ /_private_/ && item !~ /^(release_|close_)/ }
  end
  let!(:role) { create :cms_role, name: unique_id, permissions: permissions, cur_site: site }
  let!(:user1) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group.id], cms_role_ids: [role.id] }

  context "with article/page" do
    let!(:node) { create(:article_node_page, group_ids: [group.id]) }
    let!(:item1) { create :article_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :article_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:edit_public_item_path) { edit_article_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_article_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      it do
        visit edit_public_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end

      it do
        visit edit_closed_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end

      context "with form" do
        let!(:file) { create :ss_file, user_id: cms_user.id }
        let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }

        let(:column1) do
          create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
        end
        let(:column2) do
          create(:cms_column_date_field, cur_site: site, cur_form: form, required: "optional", order: 2)
        end
        let(:column3) do
          create(:cms_column_url_field2, cur_site: site, cur_form: form, required: "optional", order: 3, html_tag: '')
        end
        let(:column4) do
          create(:cms_column_text_area, cur_site: site, cur_form: form, required: "optional", order: 4)
        end
        let(:column5) do
          create(:cms_column_select, cur_site: site, cur_form: form, required: "optional", order: 5)
        end
        let(:column6) do
          create(:cms_column_radio_button, cur_site: site, cur_form: form, required: "optional", order: 6)
        end
        let(:column7) do
          create(:cms_column_check_box, cur_site: site, cur_form: form, required: "optional", order: 7)
        end
        let(:column8) do
          create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 8, file_type: "image")
        end
        let(:column9) do
          create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 9)
        end
        let(:column10) do
          create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional", order: 10)
        end
        let(:column11) do
          create(:cms_column_list, cur_site: site, cur_form: form, required: "optional", order: 11)
        end
        let(:column12) do
          create(:cms_column_table, cur_site: site, cur_form: form, required: "optional", order: 12)
        end
        let(:column13) do
          create(:cms_column_youtube, cur_site: site, cur_form: form, required: "optional", order: 13)
        end
        let(:column14) do
          create(:cms_column_select_page, cur_site: site, cur_form: form, required: "optional", order: 14, node_ids: [node.id])
        end
        let(:column_values1) do
          [
            column1.value_type.new(column: column1, value: unique_id),
            column2.value_type.new(column: column2, date: Time.zone.now),
            column3.value_type.new(column: column3, link_url: unique_id),
            column4.value_type.new(column: column4, value: unique_id),
            column5.value_type.new(column: column5, value: column5.select_options.sample),
            column6.value_type.new(column: column6, value: column6.select_options.sample),
            column7.value_type.new(column: column7, values: [column7.select_options.sample]),
            column8.value_type.new(column: column8, file: file),
            column9.value_type.new(column: column9, value: unique_id, file_ids: [file.id]),
            column10.value_type.new(column: column10, text: unique_id),
            column11.value_type.new(column: column11, lists: [unique_id]),
            column12.value_type.new(column: column12, value: unique_id),
            column13.value_type.new(column: column13, url: "https://www.youtube.com/watch?v=CSlLndeDc48"),
            column14.value_type.new(column: column14, value: [ item2.id ])
          ]
        end
        let(:column_values2) do
          [
            column1.value_type.new(column: column1, value: unique_id),
            column2.value_type.new(column: column2, date: Time.zone.now),
            column3.value_type.new(column: column3, link_url: unique_id),
            column4.value_type.new(column: column4, value: unique_id),
            column5.value_type.new(column: column5, value: column5.select_options.sample),
            column6.value_type.new(column: column6, value: column6.select_options.sample),
            column7.value_type.new(column: column7, values: [column7.select_options.sample]),
            column8.value_type.new(column: column8, file: file),
            column9.value_type.new(column: column9, value: unique_id, file_ids: [file.id]),
            column10.value_type.new(column: column10, text: unique_id),
            column11.value_type.new(column: column11, lists: [unique_id]),
            column12.value_type.new(column: column12, value: unique_id),
            column13.value_type.new(column: column13, url: "https://www.youtube.com/watch?v=CSlLndeDc48"),
            column14.value_type.new(column: column14, value: [ item1.id ])
          ]
        end

        before do
          item1.form = form
          item1.column_values = column_values1
          item1.save!
          item1.reload

          item2.form = form
          item2.column_values = column_values2
          item2.save!
          item2.reload
        end

        it do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          within ".column-value-cms-column-free" do
            wait_ckeditor_ready(find(:fillable_field, "item[column_values][][in_wrap][value]"))
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")

          within "#item-form" do
            fill_in "item[name]", with: unique_id
            within ".column-value-cms-column-free" do
              fill_in_ckeditor "item[column_values][][in_wrap][value]", with: unique_id
            end

            wait_cbox_open do
              click_on I18n.t('cms.buttons.save_as_branch')
            end
          end
          wait_for_cbox do
            expect(page).to have_css("#alertExplanation")
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          wait_for_notice I18n.t("workflow.notice.created_branch_page")

          item1.reload
          expect(item1.master?).to be_truthy
          expect(item1.branches).to have(1).items
          item1.branches.first.tap do |branch|
            expect(branch).to be_present
            expect(branch.branch?).to be_truthy
            expect(branch.master_id).to eq item1.id
          end

          within "#addon-workflow-agents-addons-branch" do
            expect(page).to have_css(".master .branches", text: item1.name)
          end
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        end

        it do
          visit edit_closed_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          within ".column-value-cms-column-free" do
            wait_ckeditor_ready(find(:fillable_field, "item[column_values][][in_wrap][value]"))
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end
    end

    context "with user1" do
      before { login_user user1 }

      it do
        visit edit_public_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_no_css(".save")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_no_css(".publish_save")

        within "#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in_ckeditor "item[html]", with: unique_id

          click_on I18n.t('cms.buttons.save_as_branch')
        end
        wait_for_notice I18n.t("workflow.notice.created_branch_page")

        item1.reload
        expect(item1.master?).to be_truthy
        expect(item1.branches).to have(1).items
        item1.branches.first.tap do |branch|
          expect(branch).to be_present
          expect(branch.branch?).to be_truthy
          expect(branch.master_id).to eq item1.id
        end

        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css(".master .branches", text: item1.name)
        end
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end

      it do
        visit edit_closed_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_no_css(".publish_save")
      end
    end

    context "when page has branch page" do
      let!(:item1_branch) { create :article_page, cur_node: node, master: item1, state: "closed", group_ids: [group.id] }
      let!(:item2_branch) { create :article_page, cur_node: node, master: item2, state: "closed", group_ids: [group.id] }

      before do
        item1.branch_ids = [ item1_branch.id ]
        item1.save!
        item2.branch_ids = [ item2_branch.id ]
        item2.save!
      end

      context "with admin" do
        before { login_cms_user }

        it do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end

        it do
          visit edit_closed_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end

      context "with user1" do
        before { login_user user1 }

        it do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_no_css(".save")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end

        it do
          visit edit_closed_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end
      end
    end

    context "with creating branch page has validation errors" do
      before { login_user user1 }

      it do
        now = Time.zone.now.change(sec: 0)
        Timecop.freeze(I18n.l(now)) do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")

          expect(page).to have_no_css(".save")
          expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
          expect(page).to have_no_css(".publish_save")

          within "#item-form" do
            fill_in "item[name]", with: unique_id
            fill_in_ckeditor "item[html]", with: unique_id

            ensure_addon_opened("#addon-cms-agents-addons-release_plan")
            within "#addon-cms-agents-addons-release_plan" do
              # set past date/time to cause validation error to "公開終了日時(予約)"
              fill_in_datetime 'item[close_date]', with: 1.day.ago.change(sec: 0)
            end

            click_on I18n.t('cms.buttons.save_as_branch')
          end
          wait_for_error I18n.t('errors.messages.greater_than', count: I18n.l(now))
        end
      end
    end
  end

  context "with cms/page" do
    let!(:node) { create(:cms_node_page, group_ids: [group.id]) }
    let!(:item1) { create :cms_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :cms_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:edit_public_item_path) { edit_node_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_node_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      it do
        visit edit_public_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end

      it do
        visit edit_closed_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end
    end

    context "with user1" do
      before { login_user user1 }

      it do
        visit edit_public_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_no_css(".save")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_no_css(".publish_save")

        within "#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in_ckeditor "item[html]", with: unique_id

          click_on I18n.t('cms.buttons.save_as_branch')
        end
        wait_for_notice I18n.t("workflow.notice.created_branch_page")

        item1.reload
        expect(item1.master?).to be_truthy
        expect(item1.branches).to have(1).items
        item1.branches.first.tap do |branch|
          expect(branch).to be_present
          expect(branch.branch?).to be_truthy
          expect(branch.master_id).to eq item1.id
        end

        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css(".master .branches", text: item1.name)
        end
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end

      it do
        visit edit_closed_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_no_css(".publish_save")
      end
    end

    context "when page has branch page" do
      let!(:item1_branch) { create :cms_page, cur_node: node, master: item1, state: "closed", group_ids: [group.id] }
      let!(:item2_branch) { create :cms_page, cur_node: node, master: item2, state: "closed", group_ids: [group.id] }

      before do
        item1.branch_ids = [ item1_branch.id ]
        item1.save!
        item2.branch_ids = [ item2_branch.id ]
        item2.save!
      end

      context "with admin" do
        before { login_cms_user }

        it do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end

        it do
          visit edit_closed_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end

      context "with user1" do
        before { login_user user1 }

        it do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css("[type='reset']", text: I18n.t("ss.buttons.cancel"))
          expect(page).to have_no_css(".save")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end

        it do
          visit edit_closed_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
          expect(page).to have_css("[type='reset']", text: I18n.t("ss.buttons.cancel"))
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end
      end
    end

    context "when page has ready branch page" do
      let!(:item1_branch) { create :cms_page, cur_node: node, master: item1, state: "ready", group_ids: [group.id] }
      let(:edit_ready_branch_path) { edit_node_page_path site.id, node, item1_branch }

      before do
        item1.branch_ids = [ item1_branch.id ]
        item1.save!
      end

      context "with admin" do
        before { login_cms_user }

        it do
          visit edit_ready_branch_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end

      context "with user1" do
        before { login_user user1 }

        it do
          visit edit_ready_branch_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end
      end
    end
  end

  context "with event/page" do
    let!(:node) { create(:event_node_page, group_ids: [group.id]) }
    let!(:item1) { create :event_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :event_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:edit_public_item_path) { edit_event_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_event_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      it do
        visit edit_public_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end

      it do
        visit edit_closed_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end
    end

    context "with user1" do
      before { login_user user1 }

      it do
        visit edit_public_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_no_css(".save")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_no_css(".publish_save")

        within "#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in_ckeditor "item[html]", with: unique_id

          click_on I18n.t('cms.buttons.save_as_branch')
        end
        wait_for_notice I18n.t("workflow.notice.created_branch_page")

        item1.reload
        expect(item1.master?).to be_truthy
        expect(item1.branches).to have(1).items
        item1.branches.first.tap do |branch|
          expect(branch).to be_present
          expect(branch.branch?).to be_truthy
          expect(branch.master_id).to eq item1.id
        end

        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css(".master .branches", text: item1.name)
        end
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end

      it do
        visit edit_closed_item_path
        # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
        wait_for_ckeditor_ready("item[html]")

        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_no_css(".publish_save")
      end
    end

    context "when page has branch page" do
      let!(:item1_branch) { create :event_page, cur_node: node, master: item1, state: "closed", group_ids: [group.id] }
      let!(:item2_branch) { create :event_page, cur_node: node, master: item2, state: "closed", group_ids: [group.id] }

      before do
        item1.branch_ids = [ item1_branch.id ]
        item1.save!
        item2.branch_ids = [ item2_branch.id ]
        item2.save!
      end

      context "with admin" do
        before { login_cms_user }

        it do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end

        it do
          visit edit_closed_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end

      context "with user1" do
        before { login_user user1 }

        it do
          visit edit_public_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_no_css(".save")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end

        it do
          visit edit_closed_item_path
          # 保存ボタンの再配置完了を待つ手段がないため、代わりに CKEditor　の完了を待つ
          wait_for_ckeditor_ready("item[html]")
          within_cbox do
            expect(page).to have_css("h2", text: I18n.t("workflow.confirm.would_you_edit_branch"))
            wait_for_cbox_closed { click_on I18n.t("workflow.links.continue_to_edit_master") }
          end

          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end
      end
    end
  end
end
