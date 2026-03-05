require 'spec_helper'

describe "inquiry_results", type: :feature, dbscope: :example, js: true do
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

    it do
      login_user admin, to: inquiry_forms_path(site: site, cid: inquiry_node)
      within first(".mod-navi") do
        expect(page).to have_link(I18n.t("inquiry.answer"))
        # article/page 配下では集計結果は確認できない。
        expect(page).to have_no_link(I18n.t("inquiry.result"))
      end
    end
  end
end
