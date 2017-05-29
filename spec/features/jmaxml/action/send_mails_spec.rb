require 'spec_helper'

describe "jmaxml/action/send_mails", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:node) { create :rss_node_weather_xml, cur_site: site }
  let(:index_path) { jmaxml_action_bases_path(site, node) }

  context "basic crud" do
    let!(:group1) { create(:cms_group, name: "#{group.name}/#{unique_id}") }
    let!(:group2) { create(:cms_group, name: "#{group.name}/#{unique_id}") }
    let!(:group3) { create(:cms_group, name: "#{group.name}/#{unique_id}") }
    let!(:user1) { create(:cms_test_user, group_ids: [ group1.id ]) }
    let!(:user2) { create(:cms_test_user, group_ids: [ group2.id ]) }
    let!(:user3) { create(:cms_test_user, group_ids: [ group2.id ]) }
    let!(:user4) { create(:cms_test_user, group_ids: [ group1.id, group3.id ]) }
    let(:model) { Jmaxml::Action::SendMail }
    let(:name1) { unique_id }
    let(:name2) { unique_id }
    let(:sender_name) { unique_id }
    let(:sender_email) { "#{sender_name}@example.jp" }
    let(:signature_text) do
      %w(
        ----
        signature text
      ).join("\n")
    end

    before { login_cms_user }

    it do
      #
      # create
      #
      visit index_path
      click_on I18n.t('ss.links.new')

      within 'form' do
        select model.model_name.human, from: 'item[in_type]'
        click_on I18n.t('views.buttons.new')
      end

      within 'form' do
        fill_in 'item[name]', with: name1
        fill_in 'item[sender_name]', with: sender_name
        fill_in 'item[sender_email]', with: sender_email
        fill_in 'item[signature_text]', with: signature_text
        click_on I18n.t('cms.apis.users.index')
      end
      within '.items' do
        click_on user1.name
      end
      within 'form' do
        click_on I18n.t('ss.apis.groups.index')
      end
      within '.items' do
        click_on group2.trailing_name
      end
      within 'form' do
        click_on I18n.t('views.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |action|
        expect(action.name).to eq name1
        expect(action.sender_name).to eq sender_name
        expect(action.sender_email).to eq sender_email
        expect(action.signature_text.split(/\r?\n/)).to eq signature_text.split(/\r?\n/)
        expect(action.recipient_user_ids).to eq [ user1.id ]
        expect(action.recipient_group_ids).to eq [ group2.id ]
        expect(action.publishing_office_state).to eq 'hide'
        expect(action.recipient_emails.sort).to eq [ user1.email, user2.email, user3.email ].sort
      end

      #
      # update
      #
      visit index_path
      click_on name1
      click_on I18n.t('ss.links.edit')

      within 'form' do
        fill_in 'item[name]', with: name2
        click_on I18n.t('views.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      expect(model.count).to eq 1
      model.first.tap do |action|
        expect(action.name).to eq name2
        expect(action.sender_name).to eq sender_name
        expect(action.sender_email).to eq sender_email
        expect(action.signature_text.split(/\r?\n/)).to eq signature_text.split(/\r?\n/)
        expect(action.recipient_user_ids).to eq [ user1.id ]
        expect(action.recipient_group_ids).to eq [ group2.id ]
        expect(action.publishing_office_state).to eq 'hide'
        expect(action.recipient_emails.sort).to eq [ user1.email, user2.email, user3.email ].sort
      end

      #
      # delete
      #
      visit index_path
      click_on name2
      click_on I18n.t('ss.links.delete')

      within 'form' do
        click_on I18n.t('views.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('views.notice.saved'), wait: 60)

      expect(model.count).to eq 0
    end
  end
end
