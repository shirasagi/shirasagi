require 'spec_helper'

describe "inquiry_answers", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group1.id, group2.id ] }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { "ua-#{unique_id}" }
  let(:state) { Inquiry::Answer::DEFAULT_STATE }
  let(:comment) { "comment-#{unique_id}" }
  let(:answer1) do
    Inquiry::Answer.new(
      cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, state: state, comment: comment,
      group_ids: [ group1.id ])
  end
  let(:answer2) do
    Inquiry::Answer.new(
      cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent, state: state, comment: comment,
      group_ids: [ group2.id ])
  end

  let(:name) { unique_id }
  let(:email) { "#{unique_id}@example.jp" }
  let(:email_confirmation) { email }
  let(:radio_value) { radio_column.select_options.sample }
  let(:select_value) { select_column.select_options.sample }
  let(:check_value) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
  let(:same_as_name) { unique_id }
  let(:name_column) { node.columns[0] }
  let(:company_column) { node.columns[1] }
  let(:email_column) { node.columns[2] }
  let(:radio_column) { node.columns[3] }
  let(:select_column) { node.columns[4] }
  let(:check_column) { node.columns[5] }
  let(:same_as_name_column) { node.columns[6] }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_same_as_name).reverse_merge({cur_site: site})
    node.reload
  end

  before do
    [ answer1, answer2 ].each do |answer|
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email]
      data[radio_column.id] = [radio_value]
      data[select_column.id] = [select_value]
      data[check_column.id] = [check_value]
      data[same_as_name_column.id] = [same_as_name]

      answer.set_data(data)
      answer.save!
    end
  end

  context "search with answer charge" do
    let!(:role) do
      permissions = %w(read_private_cms_nodes read_private_inquiry_answers edit_private_inquiry_answers)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group1.id ] }
    let(:initial_search_query) { nil }

    before { login_user user, to: inquiry_answers_path(site: site, cid: node, s: initial_search_query) }

    context "reset search query" do
      let(:initial_search_query) { { keyword: unique_id } }

      it do
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          click_on I18n.t("ss.buttons.reset")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 1)
          expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end
      end
    end

    context "with keyword" do
      let(:initial_search_query) { { keyword: unique_id } }

      context "with name" do
        it do
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 0)
            expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end

          within ".index-search" do
            fill_in "s[keyword]", with: name
            click_on I18n.t("ss.buttons.search")
          end
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 1)
            expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end

          within ".index-search" do
            fill_in "s[keyword]", with: unique_id
            click_on I18n.t("ss.buttons.search")
          end
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 0)
            expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end
        end
      end

      context "with email" do
        it do
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 0)
            expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end

          within ".index-search" do
            fill_in "s[keyword]", with: email
            click_on I18n.t("ss.buttons.search")
          end
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 1)
            expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end
        end
      end

      context "with radio_value" do
        it do
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 0)
            expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end

          within ".index-search" do
            fill_in "s[keyword]", with: radio_value
            click_on I18n.t("ss.buttons.search")
          end
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 1)
            expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end
        end
      end

      context "with select_value" do
        it do
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 0)
            expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end

          within ".index-search" do
            fill_in "s[keyword]", with: select_value
            click_on I18n.t("ss.buttons.search")
          end
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 1)
            expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end
        end
      end

      context "with check_value" do
        it do
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 0)
            expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end

          within ".index-search" do
            fill_in "s[keyword]", with: check_value.values.sample
            click_on I18n.t("ss.buttons.search")
          end
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 1)
            expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end
        end
      end

      context "with same_as_name" do
        it do
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 0)
            expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end

          within ".index-search" do
            fill_in "s[keyword]", with: same_as_name
            click_on I18n.t("ss.buttons.search")
          end
          within ".list-items" do
            expect(page).to have_css(".list-item[data-id]", count: 1)
            expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
            expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
          end
        end
      end
    end

    context "with state" do
      let(:state) { "closed" }

      it do
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select I18n.t("inquiry.options.search_answer_state.#{state}"), from: 's[state]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 1)
          expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select I18n.t("inquiry.options.search_answer_state.unclosed"), from: 's[state]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end
      end
    end

    context "with group" do
      let!(:group3) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
      let(:initial_search_query) { { group: group3.id } }

      it do
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        # 他グループの回答が見えないので、グループ選択は表示されないはず
        within ".index-search" do
          expect(page).to have_no_css("[name='s[group]']")
        end
      end
    end

    context "with year" do
      let(:now) { Time.zone.now }
      let(:initial_search_query) { { year: now.year - 3 } }

      it do
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select "#{now.year}#{I18n.t('datetime.prompts.year')}", from: 's[year]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 1)
          expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select "#{now.year - 1}#{I18n.t('datetime.prompts.year')}", from: 's[year]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end
      end
    end

    context "with year and month" do
      let(:now) { Time.zone.now }
      let(:prev_month) { now.month == 1 ? 12 : now.month - 1 }
      let(:next_month) { now.month == 12 ? 1 : now.month + 1 }
      let(:initial_search_query) { { year: now.year, month: prev_month } }

      it do
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select "#{now.year}#{I18n.t('datetime.prompts.year')}", from: 's[year]'
          select "#{now.month}#{I18n.t('datetime.prompts.month')}", from: 's[month]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 1)
          expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select "#{now.year}#{I18n.t('datetime.prompts.year')}", from: 's[year]'
          select "#{next_month}#{I18n.t('datetime.prompts.month')}", from: 's[month]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end
      end
    end
  end


  context "search with site admin" do
    let!(:user) { cms_user }
    let(:initial_search_query) { nil }

    before { login_user user, to: inquiry_answers_path(site: site, cid: node, s: initial_search_query) }

    context "with group" do
      let!(:group3) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
      let(:initial_search_query) { { group: group3.id } }

      it do
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 0)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select group1.trailing_name, from: 's[group]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 1)
          expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
          expect(page).to have_no_css(".list-item[data-id='#{answer2.id}']")
        end

        within ".index-search" do
          select group2.trailing_name, from: 's[group]'
          click_on I18n.t("ss.buttons.search")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 1)
          expect(page).to have_css(".list-item[data-id]", text: answer2.data_summary)
          expect(page).to have_no_css(".list-item[data-id='#{answer1.id}']")
        end

        within ".index-search" do
          click_on I18n.t("ss.buttons.reset")
        end
        within ".list-items" do
          expect(page).to have_css(".list-item[data-id]", count: 2)
          expect(page).to have_css(".list-item[data-id]", text: answer1.data_summary)
          expect(page).to have_css(".list-item[data-id]", text: answer2.data_summary)
        end
      end
    end
  end
end
