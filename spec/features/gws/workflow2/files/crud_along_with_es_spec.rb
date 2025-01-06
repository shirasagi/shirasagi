require 'spec_helper'

describe "gws_workflow2_files", type: :feature, dbscope: :example, js: true, es: true do
  let(:site) { gws_site }
  let!(:role) do
    permissions = %w(use_gws_workflow2 use_gws_elasticsearch)
    create(:gws_role, cur_site: site, permissions: permissions)
  end
  let!(:agent_user) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ role.id ] }
  let!(:approver_user) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ role.id ] }
  let!(:circular_user) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ role.id ] }
  let!(:dest_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:dest_user) { create :gws_user, group_ids: [ dest_group.id ], gws_role_ids: [ role.id ] }
  let!(:route) do
    create(
      :gws_workflow2_route, group_ids: gws_user.group_ids,
      approvers: [
        { "level" => 1, "user_type" => approver_user.class.name, "user_id" => approver_user.id }
      ],
      required_counts: [ false, false, false, false, false ],
      circulations: [
        { "level" => 1, "user_type" => circular_user.class.name, "user_id" => circular_user.id }
      ]
    )
  end

  before do
    # enable elastic search
    site.elasticsearch_hosts = SS::EsSupport.es_url
    site.menu_elasticsearch_state = 'show'
    site.menu_workflow2_state = 'show'
    site.save!

    # gws:es:ingest:init
    Gws::Elasticsearch.init_ingest(site: site)
    # gws:es:drop
    Gws::Elasticsearch.drop_index(site: site) rescue nil
    # gws:es:create_indexes
    Gws::Elasticsearch.create_index(site: site)
  end

  around do |example|
    perform_enqueued_jobs do
      example.call
    end
  end

  context "crud along with elasticsearch" do
    context "with approval" do
      let!(:form) do
        create(
          :gws_workflow2_form_application, cur_site: site, name: "application-#{unique_id}",
          default_route_id: route.id, state: "public", approval_state: "with_approval", agent_state: "enabled",
          destination_group_ids: [ dest_group.id ], destination_user_ids: [ dest_user.id ]
        )
      end
      let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
      let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1) }
      let!(:file) { tmp_ss_file(contents: '0123456789', user: gws_user) }
      let(:item_text) { unique_id }
      let(:workflow_comment) { unique_id }
      let(:approve_comment) { unique_id }
      let(:now) { Time.zone.now.change(sec: 0) }

      it do
        #
        # Create
        #
        login_user gws_user
        visit gws_workflow2_files_path(site, state: 'all')
        within ".nav-menu" do
          click_link I18n.t('gws/workflow2.navi.find_by_keyword')
        end
        within ".gws-workflow-select-forms-table" do
          click_on form.name
        end
        within "form#item-form" do
          within "#addon-gws-agents-addons-workflow2-custom_form" do
            fill_in "custom[#{column1.id}]", with: item_text
            wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
          end
        end
        within_cbox do
          within "article.file-view" do
            wait_for_cbox_closed { click_on file.name }
          end
        end
        within "form#item-form" do
          expect(page).to have_content(file.name)
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: approver_user.long_name)
        end

        expect(Gws::Workflow2::File.site(site).count).to eq 1
        item = Gws::Workflow2::File.site(site).first
        item_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(item.name).to eq item_name
        expect(item.column_values.count).to eq 2
        expect(item.workflow_state).to be_blank
        expect(item.workflow_user_id).to be_blank
        expect(item.workflow_agent_id).to be_blank
        expect(item.destination_group_ids).to eq form.destination_group_ids
        expect(item.destination_user_ids).to eq form.destination_user_ids
        expect(item.destination_treat_state).to eq "untreated"

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        # gws_user
        expect(item.readable?(gws_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: gws_user, state: 'all').count).to eq 1

        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        expect(page).to have_content(item_name)
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: approver_user.long_name)
        end

        # agent_user
        expect(item.readable?(agent_user, site: site)).to be_falsey
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: agent_user, state: 'all').count).to eq 0

        login_user agent_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)

        # approver_user
        expect(item.readable?(approver_user, site: site)).to be_falsey
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: approver_user, state: 'all').count).to eq 0

        login_user approver_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)

        # circular_user
        expect(item.readable?(circular_user, site: site)).to be_falsey
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: circular_user, state: 'all').count).to eq 0

        login_user circular_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)

        # dest_user
        expect(item.readable?(dest_user, site: site)).to be_falsey
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: dest_user, state: 'all').count).to eq 0

        login_user dest_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)

        #
        # 承認依頼（承認者 1 名＋回覧者 1 名）
        #
        login_user gws_user
        visit gws_workflow2_files_path(site, state: 'all')
        click_on item_name
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-request" do
          choose "item_workflow_agent_type_agent"
          wait_for_cbox_opened { click_on I18n.t("gws/workflow2.search_delegatees.index") }
        end
        within_cbox do
          wait_for_cbox_closed { click_on agent_user.long_name }
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".agent-type-agent", text: agent_user.long_name)
          fill_in "item[workflow_comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        item.reload
        expect(item.workflow_state).to eq 'request'
        expect(item.workflow_user_id).to eq agent_user.id
        expect(item.workflow_agent_id).to eq gws_user.id

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        # gws_user
        expect(item.readable?(gws_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: gws_user, state: 'all').count).to eq 1
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        # agent_user
        expect(item.readable?(agent_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: agent_user, state: 'all').count).to eq 1

        login_user agent_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        # approver_user
        expect(item.readable?(approver_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: approver_user, state: 'all').count).to eq 1

        login_user approver_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)
        end

        # circular_user
        expect(item.readable?(circular_user, site: site)).to be_falsey
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: circular_user, state: 'all').count).to eq 0

        login_user circular_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)

        # dest_user
        expect(item.readable?(dest_user, site: site)).to be_falsey
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: dest_user, state: 'all').count).to eq 0

        login_user dest_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)

        #
        # 承認する
        #
        login_user approver_user
        visit gws_workflow2_files_path(site, state: 'all')
        click_on item_name
        wait_for_turbo_frame "#workflow-approver-frame"
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        end
        within ".mod-workflow-approve" do
          fill_in "item[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.approved")

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)

          wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
          within_cbox do
            expect(page).to have_css(".approver-comment", text: approve_comment)
            wait_for_cbox_closed { find('#cboxClose').click }
          end
        end

        item.reload
        expect(item.workflow_state).to eq 'approve'

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        # gws_user
        expect(item.readable?(gws_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: gws_user, state: 'all').count).to eq 1

        login_user gws_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)

          wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
          within_cbox do
            expect(page).to have_css(".approver-comment", text: approve_comment)
            wait_for_cbox_closed { find('#cboxClose').click }
          end
        end

        # agent_user
        expect(item.readable?(agent_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: agent_user, state: 'all').count).to eq 1

        login_user agent_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)

          wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
          within_cbox do
            expect(page).to have_css(".approver-comment", text: approve_comment)
            wait_for_cbox_closed { find('#cboxClose').click }
          end
        end

        # approver_user
        expect(item.readable?(approver_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: approver_user, state: 'all').count).to eq 1

        login_user approver_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)

          wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
          within_cbox do
            expect(page).to have_css(".approver-comment", text: approve_comment)
            wait_for_cbox_closed { find('#cboxClose').click }
          end
        end

        # circular_user
        expect(item.readable?(circular_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: circular_user, state: 'all').count).to eq 1

        login_user circular_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)

          wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
          within_cbox do
            expect(page).to have_css(".approver-comment", text: approve_comment)
            wait_for_cbox_closed { find('#cboxClose').click }
          end
        end

        # dest_user
        expect(item.readable?(dest_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: dest_user, state: 'all').count).to eq 1

        login_user dest_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
          expect(page).to have_css(".workflow_comment", text: workflow_comment)

          wait_for_cbox_opened { find('.workflow_approvers tr:nth-child(1) .approver_comment').click }
          within_cbox do
            expect(page).to have_css(".approver-comment", text: approve_comment)
            wait_for_cbox_closed { find('#cboxClose').click }
          end
        end
      end
    end

    context "without approval" do
      let!(:form) do
        create(
          :gws_workflow2_form_application, cur_site: site, name: "application-#{unique_id}", state: "public",
          approval_state: "without_approval", agent_state: "enabled",
          destination_group_ids: [ dest_group.id ], destination_user_ids: [ dest_user.id ]
        )
      end
      let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
      let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1) }
      let!(:file) { tmp_ss_file(contents: '0123456789', user: gws_user) }
      let(:item_text) { unique_id }
      # let(:workflow_comment) { unique_id }
      # let(:approve_comment) { unique_id }
      let(:now) { Time.zone.now.change(sec: 0) }

      it do
        #
        # Create
        #
        login_user gws_user
        visit gws_workflow2_files_path(site, state: 'all')
        within ".nav-menu" do
          click_link I18n.t('gws/workflow2.navi.find_by_keyword')
        end
        within ".gws-workflow-select-forms-table" do
          click_on form.name
        end
        within "form#item-form" do
          within "#addon-gws-agents-addons-workflow2-custom_form" do
            fill_in "custom[#{column1.id}]", with: item_text
            wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
          end
        end
        within_cbox do
          within "article.file-view" do
            wait_for_cbox_closed { click_on file.name }
          end
        end
        within "form#item-form" do
          expect(page).to have_content(file.name)
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_turbo_frame "#workflow-approver-frame"

        I18n.t("gws/workflow2.request_notice_without_approval").tap do |notices|
          expect(page).to have_css(".workflow-request-notice-item", text: notices.first)
        end

        expect(Gws::Workflow2::File.site(site).count).to eq 1
        item = Gws::Workflow2::File.site(site).first
        item_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
        expect(item.name).to eq item_name
        expect(item.column_values.count).to eq 2
        expect(item.workflow_state).to be_blank
        expect(item.workflow_user_id).to be_blank
        expect(item.workflow_agent_id).to be_blank
        expect(item.destination_group_ids).to eq form.destination_group_ids
        expect(item.destination_user_ids).to eq form.destination_user_ids
        expect(item.destination_treat_state).to eq "untreated"

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        # gws_user
        expect(item.readable?(gws_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: gws_user, state: 'all').count).to eq 1

        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        I18n.t("gws/workflow2.request_notice_without_approval").tap do |notices|
          expect(page).to have_css(".workflow-request-notice-item", text: notices.first)
        end

        # dest_user
        expect(item.readable?(dest_user, site: site)).to be_falsey
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: dest_user, state: 'all').count).to eq 0

        login_user dest_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".list-item", count: 0)

        #
        # 申請（承認なし）
        #
        login_user gws_user
        visit gws_workflow2_files_path(site, state: 'all')
        click_on item_name
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-request" do
          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_notice I18n.t("gws/workflow2.notice.requested")
        wait_for_turbo_frame "#workflow-approver-frame"

        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve_without_approval"))
        end

        item.reload
        expect(item.workflow_state).to eq 'approve_without_approval'
        expect(item.workflow_user_id).to eq gws_user.id
        expect(item.workflow_agent_id).to be_blank

        # wait for indexing
        Gws::Elasticsearch.refresh_index(site: site)

        # gws_user
        expect(item.readable?(gws_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: gws_user, state: 'all').count).to eq 1
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve_without_approval"))
        end

        # dest_user
        expect(item.readable?(dest_user, site: site)).to be_truthy
        expect(Gws::Workflow2::File.search(cur_site: site, cur_user: dest_user, state: 'all').count).to eq 1

        login_user dest_user
        visit gws_elasticsearch_search_main_path(site: site)
        within "form#item-form" do
          fill_in "s[keyword]", with: "*:*"
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 2)
          expect(page).to have_css(".list-item[data-id='gws_workflow2_files-workflow2-#{item.id}']", text: item_name)
          expect(page).to have_css(".list-item[data-id='file-#{file.id}']", text: file.name)
          click_on item_name
        end
        wait_for_turbo_frame "#workflow-approver-frame"
        expect(page).to have_content(item_name)
        within ".mod-workflow-view" do
          expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve_without_approval"))
        end
      end
    end
  end
end
