require 'spec_helper'

describe "member_my_anpi_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:member) do
    create(:cms_member,
      cur_site: site,
      name: unique_id,
      email: "#{unique_id}@example.jp",
      in_password: "abc123",
      in_password_again: "abc123",
      kana: unique_id,
      job: unique_id,
      postal_code: '1050001',
      addr: "東京都港区虎ノ門#{unique_id}",
      sex: 'male',
      birthday: Date.parse("1988/10/10"))
  end
  let(:text0) { unique_id }
  let(:text1) { unique_id }
  let(:node) { create :member_node_my_anpi_post, cur_site: site }
  let(:index_path) { member_my_anpi_posts_path site.id, node }

  after(:all) do
    WebMock.reset!
  end

  context "basic crud" do
    before { login_cms_user }

    it do
      visit index_path
      expect(current_path).to eq index_path

      click_on I18n.t('ss.links.new')
      within "form#item-form" do
        fill_in 'item[name]', with: member.name
        fill_in 'item[kana]', with: member.kana
        fill_in 'item[addr]', with: member.addr
        select I18n.t("member.options.sex.#{member.sex}"), from: 'item[sex]'
        fill_in 'item[age]', with: member.age
        fill_in 'item[email]', with: member.email
        fill_in 'item[text]', with: text0
        wait_cbox_open { click_on 'メンバーを選択する' }
      end
      within_cbox do
        wait_cbox_close { click_link member.name }
      end
      within "form#item-form" do
        expect(page).to have_css(".ajax-selected", text: member.name)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Board::AnpiPost.count).to eq 1
      Board::AnpiPost.first.tap do |anpi|
        expect(anpi.member_id).to eq member.id
        expect(anpi.name).to eq member.name
        expect(anpi.text).to eq text0
      end

      click_on I18n.t('ss.links.back_to_index')
      expect(current_path).to eq index_path
      expect(page).to have_css('.list-item .title', text: member.name)

      click_on member.name
      click_on I18n.t('ss.links.edit')
      within "form#item-form" do
        fill_in 'item[text]', with: text1
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Board::AnpiPost.count).to eq 1
      Board::AnpiPost.first.tap do |anpi|
        expect(anpi.member_id).to eq member.id
        expect(anpi.name).to eq member.name
        expect(anpi.text).to eq text1
      end

      visit index_path
      click_on member.name
      click_on I18n.t('ss.links.delete')
      click_on I18n.t("ss.buttons.delete")
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end

  context "download" do
    let!(:item) { create :board_anpi_post, cur_site: site, cur_member: member, text: unique_id }

    before { login_cms_user }

    it do
      visit index_path
      expect(page).to have_css('.list-item .title', text: item.name)
      click_on 'ダウンロード'
      expect(page).to have_css('.list-item .title', text: item.name)
    end
  end

  context "post to google person finder" do
    let!(:item) { create :board_anpi_post, cur_site: site, cur_member: member, text: unique_id }
    let(:repository) { Google::PersonFinder.new.repository }
    let(:api_key) { Google::PersonFinder.new.api_key }
    let(:ptf_url) do
      "https://www.google.org/personfinder/#{repository}/api/write?#{{key: api_key}.to_param}"
    end
    let(:response) { File.read(Rails.root.join('spec', 'fixtures', 'google', 'person-finder-error.xml')) }

    before do
      stub_request(:post, ptf_url).
        to_return(body: response, status: 200, headers: { 'Content-Type' => 'application/xml' })

      login_cms_user
    end

    it do
      visit index_path
      click_on item.name
      click_on 'Google Person Finderに安否情報を提供する'
      click_on '登録'
      wait_for_notice 'Google Person Finder に登録しました。', wait: 60
    end
  end
end
