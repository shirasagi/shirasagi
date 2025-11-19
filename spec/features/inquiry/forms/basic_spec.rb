require 'spec_helper'

describe "inquiry_forms", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :inquiry_node_node, cur_site: site }
  let!(:faq_node) { create :faq_node_page, cur_site: site }
  let!(:faq_node2) { create :faq_node_page, cur_site: site }
  let(:index_path) { inquiry_nodes_path site.id, node }
  let(:now) { Time.zone.now.change(sec: 0) }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:basename) { "basename-#{unique_id}" }
    # inquiry/addon/message
    let(:inquiry_show_sent_data) { %w(disabled enabled).sample }
    let(:inquiry_show_sent_data_label) { I18n.t("ss.options.state.#{inquiry_show_sent_data}") }
    let(:inquiry_html) do
      <<~HTML
        <div class="inquiry-html">
          <p>#{unique_id}</p>
          <p>#{unique_id}</p>
        </div>
      HTML
    end
    let(:inquiry_sent_html) do
      <<~HTML
        <div class="inquiry-sent">
          <p>#{unique_id}</p>
          <p>#{unique_id}</p>
        </div>
      HTML
    end
    let(:inquiry_results_html) do
      <<~HTML
        <div class="inquiry-results">
          <p>#{unique_id}</p>
          <p>#{unique_id}</p>
        </div>
      HTML
    end
    # inquiry/addon/captcha
    let(:inquiry_captcha) { %w(disabled enabled).sample }
    let(:inquiry_captcha_label) { I18n.t("inquiry.options.state.#{inquiry_captcha}") }
    # inquiry/addon/notice
    let(:notice_state) { %w(disabled enabled).sample }
    let(:notice_state_label) { I18n.t("inquiry.options.state.#{notice_state}") }
    let(:notice_content) { %w(link_only include_answers).sample }
    let(:notice_content_label) { I18n.t("inquiry.options.notice_content.#{notice_content}") }
    let(:notice_emails) { Array.new(2) { unique_email } }
    let(:from_name) { "from_name-#{unique_id}" }
    let(:from_email) { unique_email }
    # inquiry/addon/reply
    let(:reply_state) { %w(disabled enabled).sample }
    let(:reply_state_label) { I18n.t("inquiry.options.state.#{reply_state}") }
    let(:reply_subject) { "reply_subject-#{unique_id}" }
    let(:reply_upper_text) { Array.new(2) { "reply_upper_text-#{unique_id}" } }
    let(:reply_content_state) { [ nil, "static", "answer" ].sample }
    let(:reply_content_state_label) do
      if reply_content_state
        I18n.t("inquiry.options.reply_content_state.#{reply_content_state}")
      else
        ""
      end
    end
    let(:reply_content_static) { Array.new(2) { "reply_content_static-#{unique_id}" } }
    let(:reply_lower_text) { Array.new(2) { "reply_lower_text-#{unique_id}" } }
    # inquiry/addon/aggregation
    let(:aggregation_state) { %w(disabled enabled).sample }
    let(:aggregation_state_label) { I18n.t("inquiry.options.state.#{aggregation_state}") }
    # inquiry/addon/kintone_app/setting
    let(:kintone_app_activation) { %w(disabled enabled).sample }
    let(:kintone_app_activation_label) { I18n.t("ss.options.state.#{kintone_app_activation}") }
    let(:kintone_app_api_token) { "kintone_app_api_token-#{unique_id}" }
    let(:kintone_app_key) { "kintone_app_key-#{unique_id}" }
    let(:kintone_app_guest_space_id) { "kintone_app_guest_space_id-#{unique_id}" }
    let(:kintone_app_guest_space_id) { "kintone_app_guest_space_id-#{unique_id}" }
    let(:kintone_app_remote_addr_field_code) { "kintone_app_remote_addr_field_code-#{unique_id}" }
    let(:kintone_app_user_agent_field_code) { "kintone_app_user_agent_field_code-#{unique_id}" }
    # inquiry/addon/reception_plan
    let(:reception_start_date) { now.to_date - 3.days }
    let(:reception_close_date) { now.to_date + 3.days }

    let(:name2) { "name-#{unique_id}" }
    # inquiry/addon/message
    let(:inquiry_show_sent_data2) { %w(disabled enabled).sample }
    let(:inquiry_show_sent_data_label2) { I18n.t("ss.options.state.#{inquiry_show_sent_data2}") }
    let(:inquiry_html2) do
      <<~HTML
        <div class="inquiry-html2">
          <p>#{unique_id}</p>
          <p>#{unique_id}</p>
        </div>
      HTML
    end
    let(:inquiry_sent_html2) do
      <<~HTML
        <div class="inquiry-sent2">
          <p>#{unique_id}</p>
          <p>#{unique_id}</p>
        </div>
      HTML
    end
    let(:inquiry_results_html2) do
      <<~HTML
        <div class="inquiry-results2">
          <p>#{unique_id}</p>
          <p>#{unique_id}</p>
        </div>
      HTML
    end
    # inquiry/addon/captcha
    let(:inquiry_captcha2) { %w(disabled enabled).sample }
    let(:inquiry_captcha_label2) { I18n.t("inquiry.options.state.#{inquiry_captcha2}") }
    # inquiry/addon/notice
    let(:notice_state2) { %w(disabled enabled).sample }
    let(:notice_state_label2) { I18n.t("inquiry.options.state.#{notice_state2}") }
    let(:notice_content2) { %w(link_only include_answers).sample }
    let(:notice_content_label2) { I18n.t("inquiry.options.notice_content.#{notice_content2}") }
    let(:notice_emails2) { Array.new(2) { unique_email } }
    let(:from_name2) { "from_name-#{unique_id}" }
    let(:from_email2) { unique_email }
    # inquiry/addon/reply
    let(:reply_state2) { %w(disabled enabled).sample }
    let(:reply_state_label2) { I18n.t("inquiry.options.state.#{reply_state2}") }
    let(:reply_subject2) { "reply_subject-#{unique_id}" }
    let(:reply_upper_text2) { Array.new(2) { "reply_upper_text-#{unique_id}" } }
    let(:reply_content_state2) { [ nil, "static", "answer" ].sample }
    let(:reply_content_state_label2) do
      if reply_content_state2
        I18n.t("inquiry.options.reply_content_state.#{reply_content_state2}")
      else
        ""
      end
    end
    let(:reply_content_static2) { Array.new(2) { "reply_content_static-#{unique_id}" } }
    let(:reply_lower_text2) { Array.new(2) { "reply_lower_text-#{unique_id}" } }
    # inquiry/addon/aggregation
    let(:aggregation_state2) { %w(disabled enabled).sample }
    let(:aggregation_state_label2) { I18n.t("inquiry.options.state.#{aggregation_state2}") }
    # inquiry/addon/kintone_app/setting
    let(:kintone_app_activation2) { %w(disabled enabled).sample }
    let(:kintone_app_activation_label2) { I18n.t("ss.options.state.#{kintone_app_activation2}") }
    let(:kintone_app_api_token2) { "kintone_app_api_token-#{unique_id}" }
    let(:kintone_app_key2) { "kintone_app_key-#{unique_id}" }
    let(:kintone_app_guest_space_id2) { "kintone_app_guest_space_id-#{unique_id}" }
    let(:kintone_app_guest_space_id2) { "kintone_app_guest_space_id-#{unique_id}" }
    let(:kintone_app_remote_addr_field_code2) { "kintone_app_remote_addr_field_code-#{unique_id}" }
    let(:kintone_app_user_agent_field_code2) { "kintone_app_user_agent_field_code-#{unique_id}" }
    # inquiry/addon/reception_plan
    let(:reception_start_date2) { now.to_date - 4.days }
    let(:reception_close_date2) { now.to_date + 4.days }

    it do
      login_user user, to: index_path
      wait_for_all_turbo_frames
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[basename]", with: basename

        # inquiry/addon/message
        ensure_addon_opened "#addon-inquiry-agents-addons-message"
        within "#addon-inquiry-agents-addons-message" do
          select inquiry_show_sent_data_label, from: "item[inquiry_show_sent_data]"
          fill_in_ckeditor "item[inquiry_html]", with: inquiry_html
          fill_in_ckeditor "item[inquiry_sent_html]", with: inquiry_sent_html
          fill_in_ckeditor "item[inquiry_results_html]", with: inquiry_results_html
        end

        # inquiry/addon/captcha
        ensure_addon_opened "#addon-inquiry-agents-addons-captcha"
        within "#addon-inquiry-agents-addons-captcha" do
          select inquiry_captcha_label, from: "item[inquiry_captcha]"
        end

        # inquiry/addon/notice
        ensure_addon_opened "#addon-inquiry-agents-addons-notice"
        within "#addon-inquiry-agents-addons-notice" do
          select notice_state_label, from: "item[notice_state]"
          select notice_content_label, from: "item[notice_content]"
          fill_in "item[notice_emails]", with: notice_emails.join("\n")
          fill_in "item[from_name]", with: from_name
          fill_in "item[from_email]", with: from_email
        end

        # inquiry/addon/reply
        ensure_addon_opened "#addon-inquiry-agents-addons-reply"
        within "#addon-inquiry-agents-addons-reply" do
          select reply_state_label, from: "item[reply_state]"
          fill_in "item[reply_subject]", with: reply_subject
          fill_in "item[reply_upper_text]", with: reply_upper_text.join("\n")
          select reply_content_state_label, from: "item[reply_content_state]"
          fill_in "item[reply_content_static]", with: reply_content_static.join("\n")
          fill_in "item[reply_lower_text]", with: reply_lower_text.join("\n")
        end

        # inquiry/addon/aggregation
        ensure_addon_opened "#addon-inquiry-agents-addons-aggregation"
        within "#addon-inquiry-agents-addons-aggregation" do
          select aggregation_state_label, from: "item[aggregation_state]"
        end

        # inquiry/addon/faq
        ensure_addon_opened "#addon-inquiry-agents-addons-faq"
        within "#addon-inquiry-agents-addons-faq" do
          wait_for_cbox_opened { click_on I18n.t("cms.apis.nodes.index") }
        end
      end
      within_cbox do
        expect(page).to have_css("tr[data-id='#{faq_node.id}']", text: faq_node.name)
        wait_for_cbox_closed { click_on faq_node.name }
      end
      within "form#item-form" do
        # inquiry/addon/faq
        within "#addon-inquiry-agents-addons-faq" do
          expect(page).to have_css("[data-id='#{faq_node.id}']", text: faq_node.name)
        end

        # inquiry/addon/kintone_app/setting
        ensure_addon_opened "#addon-inquiry-agents-addons-kintone_app-setting"
        within "#addon-inquiry-agents-addons-kintone_app-setting" do
          select kintone_app_activation_label, from: "item[kintone_app_activation]"
          fill_in "item[kintone_app_api_token]", with: kintone_app_api_token
          fill_in "item[kintone_app_key]", with: kintone_app_key
          fill_in "item[kintone_app_guest_space_id]", with: kintone_app_guest_space_id
          fill_in "item[kintone_app_remote_addr_field_code]", with: kintone_app_remote_addr_field_code
          fill_in "item[kintone_app_user_agent_field_code]", with: kintone_app_user_agent_field_code
        end

        # inquiry/addon/reception_plan
        ensure_addon_opened "#addon-inquiry-agents-addons-reception_plan"
        within "#addon-inquiry-agents-addons-reception_plan" do
          fill_in_date "item[reception_start_date]", with: reception_start_date
          fill_in_date "item[reception_close_date]", with: reception_close_date
        end

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Inquiry::Node::Form.all.count).to eq 1
      Inquiry::Node::Form.all.first.tap do |form_node|
        expect(form_node.site_id).to eq site.id
        expect(form_node.parent.id).to eq node.id
        expect(form_node.name).to eq name
        expect(form_node.basename).to eq basename
        # inquiry/addon/message
        expect(form_node.inquiry_show_sent_data).to eq inquiry_show_sent_data
        expect(form_node.inquiry_html).to include('class="inquiry-html"')
        expect(form_node.inquiry_sent_html).to include('class="inquiry-sent"')
        expect(form_node.inquiry_results_html).to include('class="inquiry-results"')
        # inquiry/addon/captcha
        expect(form_node.inquiry_captcha).to eq inquiry_captcha
        # inquiry/addon/notice
        expect(form_node.notice_state).to eq notice_state
        expect(form_node.notice_content).to eq notice_content
        expect(form_node.notice_emails).to eq notice_emails
        expect(form_node.from_name).to eq from_name
        expect(form_node.from_email).to eq from_email
        # inquiry/addon/reply
        expect(form_node.reply_state).to eq reply_state
        expect(form_node.reply_subject).to eq reply_subject
        expect(form_node.reply_upper_text).to eq reply_upper_text.join("\r\n")
        expect(form_node.reply_content_state).to eq reply_content_state
        expect(form_node.reply_content_static).to eq reply_content_static.join("\r\n")
        expect(form_node.reply_lower_text).to eq reply_lower_text.join("\r\n")
        # inquiry/addon/aggregation
        expect(form_node.aggregation_state).to eq aggregation_state
        # inquiry/addon/faq
        expect(form_node.faq_id).to eq faq_node.id
        # inquiry/addon/kintone_app/setting
        expect(form_node.kintone_app_activation).to eq kintone_app_activation
        expect(form_node.kintone_app_api_token).to eq kintone_app_api_token
        expect(form_node.kintone_app_key).to eq kintone_app_key
        expect(form_node.kintone_app_guest_space_id).to eq kintone_app_guest_space_id
        expect(form_node.kintone_app_remote_addr_field_code).to eq kintone_app_remote_addr_field_code
        expect(form_node.kintone_app_user_agent_field_code).to eq kintone_app_user_agent_field_code
        # inquiry/addon/reception_plan
        expect(form_node.reception_start_date.in_time_zone).to eq reception_start_date.in_time_zone
        expect(form_node.reception_close_date.in_time_zone).to eq reception_close_date.in_time_zone
      end

      visit index_path
      wait_for_all_turbo_frames
      within ".list-items" do
        click_on name
      end
      click_on I18n.t("cms.node_config")
      wait_for_all_ckeditors_ready
      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: name2

        # inquiry/addon/message
        ensure_addon_opened "#addon-inquiry-agents-addons-message"
        within "#addon-inquiry-agents-addons-message" do
          select inquiry_show_sent_data_label2, from: "item[inquiry_show_sent_data]"
          fill_in_ckeditor "item[inquiry_html]", with: inquiry_html2
          fill_in_ckeditor "item[inquiry_sent_html]", with: inquiry_sent_html2
          fill_in_ckeditor "item[inquiry_results_html]", with: inquiry_results_html2
        end

        # inquiry/addon/captcha
        ensure_addon_opened "#addon-inquiry-agents-addons-captcha"
        within "#addon-inquiry-agents-addons-captcha" do
          select inquiry_captcha_label2, from: "item[inquiry_captcha]"
        end

        # inquiry/addon/notice
        ensure_addon_opened "#addon-inquiry-agents-addons-notice"
        within "#addon-inquiry-agents-addons-notice" do
          select notice_state_label2, from: "item[notice_state]"
          select notice_content_label2, from: "item[notice_content]"
          fill_in "item[notice_emails]", with: notice_emails2.join("\n")
          fill_in "item[from_name]", with: from_name2
          fill_in "item[from_email]", with: from_email2
        end

        # inquiry/addon/reply
        ensure_addon_opened "#addon-inquiry-agents-addons-reply"
        within "#addon-inquiry-agents-addons-reply" do
          select reply_state_label2, from: "item[reply_state]"
          fill_in "item[reply_subject]", with: reply_subject2
          fill_in "item[reply_upper_text]", with: reply_upper_text2.join("\n")
          select reply_content_state_label2, from: "item[reply_content_state]"
          fill_in "item[reply_content_static]", with: reply_content_static2.join("\n")
          fill_in "item[reply_lower_text]", with: reply_lower_text2.join("\n")
        end

        # inquiry/addon/aggregation
        ensure_addon_opened "#addon-inquiry-agents-addons-aggregation"
        within "#addon-inquiry-agents-addons-aggregation" do
          select aggregation_state_label2, from: "item[aggregation_state]"
        end

        # inquiry/addon/faq
        ensure_addon_opened "#addon-inquiry-agents-addons-faq"
        within "#addon-inquiry-agents-addons-faq" do
          wait_for_cbox_opened { click_on I18n.t("cms.apis.nodes.index") }
        end
      end
      within_cbox do
        expect(page).to have_css("tr[data-id='#{faq_node2.id}']", text: faq_node2.name)
        wait_for_cbox_closed { click_on faq_node2.name }
      end
      within "form#item-form" do
        # inquiry/addon/faq
        within "#addon-inquiry-agents-addons-faq" do
          expect(page).to have_css("[data-id='#{faq_node2.id}']", text: faq_node2.name)
        end

        # inquiry/addon/kintone_app/setting
        ensure_addon_opened "#addon-inquiry-agents-addons-kintone_app-setting"
        within "#addon-inquiry-agents-addons-kintone_app-setting" do
          select kintone_app_activation_label2, from: "item[kintone_app_activation]"
          fill_in "item[kintone_app_api_token]", with: kintone_app_api_token2
          fill_in "item[kintone_app_key]", with: kintone_app_key2
          fill_in "item[kintone_app_guest_space_id]", with: kintone_app_guest_space_id2
          fill_in "item[kintone_app_remote_addr_field_code]", with: kintone_app_remote_addr_field_code2
          fill_in "item[kintone_app_user_agent_field_code]", with: kintone_app_user_agent_field_code2
        end

        # inquiry/addon/reception_plan
        ensure_addon_opened "#addon-inquiry-agents-addons-reception_plan"
        within "#addon-inquiry-agents-addons-reception_plan" do
          fill_in_date "item[reception_start_date]", with: reception_start_date2
          fill_in_date "item[reception_close_date]", with: reception_close_date2
        end

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Inquiry::Node::Form.all.count).to eq 1
      Inquiry::Node::Form.all.first.tap do |form_node|
        expect(form_node.site_id).to eq site.id
        expect(form_node.parent.id).to eq node.id
        expect(form_node.name).to eq name2
        expect(form_node.basename).to eq basename
        # inquiry/addon/message
        expect(form_node.inquiry_show_sent_data).to eq inquiry_show_sent_data2
        expect(form_node.inquiry_html).to include('class="inquiry-html2"')
        expect(form_node.inquiry_sent_html).to include('class="inquiry-sent2"')
        expect(form_node.inquiry_results_html).to include('class="inquiry-results2"')
        # inquiry/addon/captcha
        expect(form_node.inquiry_captcha).to eq inquiry_captcha2
        # inquiry/addon/notice
        expect(form_node.notice_state).to eq notice_state2
        expect(form_node.notice_content).to eq notice_content2
        expect(form_node.notice_emails).to eq notice_emails2
        expect(form_node.from_name).to eq from_name2
        expect(form_node.from_email).to eq from_email2
        # inquiry/addon/reply
        expect(form_node.reply_state).to eq reply_state2
        expect(form_node.reply_subject).to eq reply_subject2
        expect(form_node.reply_upper_text).to eq reply_upper_text2.join("\r\n")
        expect(form_node.reply_content_state).to eq reply_content_state2
        expect(form_node.reply_content_static).to eq reply_content_static2.join("\r\n")
        expect(form_node.reply_lower_text).to eq reply_lower_text2.join("\r\n")
        # inquiry/addon/aggregation
        expect(form_node.aggregation_state).to eq aggregation_state2
        # inquiry/addon/faq
        expect(form_node.faq_id).to eq faq_node2.id
        # inquiry/addon/kintone_app/setting
        expect(form_node.kintone_app_activation).to eq kintone_app_activation2
        expect(form_node.kintone_app_api_token).to eq kintone_app_api_token2
        expect(form_node.kintone_app_key).to eq kintone_app_key2
        expect(form_node.kintone_app_guest_space_id).to eq kintone_app_guest_space_id2
        expect(form_node.kintone_app_remote_addr_field_code).to eq kintone_app_remote_addr_field_code2
        expect(form_node.kintone_app_user_agent_field_code).to eq kintone_app_user_agent_field_code2
        # inquiry/addon/reception_plan
        expect(form_node.reception_start_date.in_time_zone).to eq reception_start_date2.in_time_zone
        expect(form_node.reception_close_date.in_time_zone).to eq reception_close_date2.in_time_zone
      end

      visit index_path
      wait_for_all_turbo_frames
      within ".cms-nodes-tree" do
        click_on name2
      end
      click_on I18n.t("cms.node_config")
      wait_for_all_ckeditors_ready
      click_on I18n.t("ss.links.delete")
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Inquiry::Node::Form.all.count).to eq 0
    end
  end
end
