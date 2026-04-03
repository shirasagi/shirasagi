require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  context "inquiry under article node" do
    let!(:article_node) { create :article_node_page, cur_site: site, group_ids: admin.group_ids }
    let(:inquiry_node) { article_node.becomes_with_route("inquiry/form") }

    let(:answer1) do
      remote_addr = Array.new(4) { rand(0..255).to_s }.join(".")
      user_agent = "ua-#{unique_id}"
      state = Inquiry::Answer::DEFAULT_STATE
      comment = "comment-#{unique_id}"
      Timecop.freeze(now - 5.hours) do
        Inquiry::Answer.new(
          cur_site: site, cur_node: inquiry_node, remote_addr: remote_addr, user_agent: user_agent, state: state,
          comment: comment, group_ids: admin.group_ids)
      end
    end
    let(:answer2) do
      remote_addr = Array.new(4) { rand(0..255).to_s }.join(".")
      user_agent = "ua-#{unique_id}"
      state = Inquiry::Answer::DEFAULT_STATE
      comment = "comment-#{unique_id}"
      Timecop.freeze(now - 4.hours) do
        Inquiry::Answer.new(
          cur_site: site, cur_node: inquiry_node, remote_addr: remote_addr, user_agent: user_agent, state: state,
          comment: comment, group_ids: admin.group_ids)
      end
    end

    before do
      name_column = attributes_for(:inquiry_column_name).then do |attributes|
        attributes[:cur_site] = site
        attributes[:question] = 'enabled'
        inquiry_node.columns.create! attributes
      end
      attributes_for(:inquiry_column_optional).then do |attributes|
        attributes[:cur_site] = site
        inquiry_node.columns.create! attributes
      end
      email_column = attributes_for(:inquiry_column_email).then do |attributes|
        attributes[:cur_site] = site
        attributes[:question] = 'enabled'
        inquiry_node.columns.create! attributes
      end
      radio_column = attributes_for(:inquiry_column_radio).then do |attributes|
        attributes[:cur_site] = site
        inquiry_node.columns.create! attributes
      end
      select_column = attributes_for(:inquiry_column_select).then do |attributes|
        attributes[:cur_site] = site
        inquiry_node.columns.create! attributes
      end
      check_column = attributes_for(:inquiry_column_check).then do |attributes|
        attributes[:cur_site] = site
        inquiry_node.columns.create! attributes
      end
      same_as_name_column = attributes_for(:inquiry_column_same_as_name).then do |attributes|
        attributes[:cur_site] = site
        inquiry_node.columns.create! attributes
      end
      inquiry_node.reload

      [ answer1, answer2 ].each do |answer|
        data = {}
        data[name_column.id] = [ unique_id ]
        unique_email.then { data[email_column.id] = [ _1, _1 ] }
        data[radio_column.id] = [ radio_column.select_options.sample ]
        data[select_column.id] = [ select_column.select_options.sample ]
        data[check_column.id] = [ Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] ]
        data[same_as_name_column.id] = [ unique_id ]

        answer.set_data(data)
        answer.save!
      end
    end

    let(:new_comment) { "comment-#{unique_id}" }

    it do
      login_user admin, to: inquiry_forms_path(site: site, cid: inquiry_node)
      within first(".mod-navi") do
        click_on I18n.t("inquiry.answer")
      end
      expect(page).to have_css(".list-item[data-id='#{answer1.id}']", text: answer1.data_summary)
      expect(page).to have_css(".list-item[data-id='#{answer2.id}']", text: answer2.data_summary)

      #
      # Edit
      #
      click_on answer1.data_summary
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        select I18n.t("inquiry.options.answer_state.closed"), from: 'item[state]'
        fill_in "item[comment]", with: new_comment
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Inquiry::Answer.find(answer1.id).tap do |answer_after_closed|
        expect(answer_after_closed.state).to eq "closed"
        expect(answer_after_closed.comment).to eq new_comment
        expect(answer_after_closed.data_summary).to eq answer1.data_summary
      end

      #
      # Delete
      #
      visit inquiry_forms_path(site: site, cid: inquiry_node)
      within first(".mod-navi") do
        click_on I18n.t("inquiry.answer")
      end

      click_on answer2.data_summary
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { answer2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
