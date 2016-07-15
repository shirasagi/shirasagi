require 'spec_helper'

describe 'board_agents_nodes_anpi_post', dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) { create :board_node_anpi_post, cur_site: site, layout_id: layout.id }
  let(:member) do
    create(:cms_member,
      cur_site: site,
      name: unique_id,
      email: "#{unique_id}@example.jp",
      in_password: 'abc123',
      in_password_again: 'abc123',
      kana: unique_id,
      job: unique_id,
      postal_code: '1050001',
      addr: "東京都港区虎ノ門#{unique_id}",
      sex: 'male',
      birthday: Date.parse('1988/10/10'))
  end

  context 'search public post' do
    let!(:item) do
      create :board_anpi_post, cur_site: site, cur_member: member, text: "#{unique_id}\n#{unique_id}", public_scope: 'public'
    end

    it 'by name' do
      visit node.url
      fill_in 'keyword', with: item.name
      click_on '人を探す'

      expect(page).to have_css('.anpi-post .title', text: item.name)
      expect(page).to have_css('.anpi-post .body', text: item.text.split("\n")[0])
      expect(page).to have_css('.anpi-post .date', text: I18n.l(item.updated, format: :long))
      expect(page).to have_css('.anpi-post .kana', text: item.kana)
      expect(page).to have_css('.anpi-post .addr', text: item.addr)
      expect(page).to have_css('.anpi-post .sex', text: I18n.t("member.options.sex.#{item.sex}"))
      expect(page).to have_css('.anpi-post .age', text: item.age)
      expect(page).to have_css('.anpi-post .member', text: item.member.name)
    end

    it 'by kana' do
      visit node.url
      fill_in 'keyword', with: item.kana
      click_on '人を探す'

      expect(page).to have_css('.anpi-post .title', text: item.name)
      expect(page).to have_css('.anpi-post .body', text: item.text.split("\n")[0])
      expect(page).to have_css('.anpi-post .date', text: I18n.l(item.updated, format: :long))
      expect(page).to have_css('.anpi-post .kana', text: item.kana)
      expect(page).to have_css('.anpi-post .addr', text: item.addr)
      expect(page).to have_css('.anpi-post .sex', text: I18n.t("member.options.sex.#{item.sex}"))
      expect(page).to have_css('.anpi-post .age', text: item.age)
      expect(page).to have_css('.anpi-post .member', text: item.member.name)
    end

    it 'by addr' do
      visit node.url
      fill_in 'keyword', with: item.addr
      click_on '人を探す'

      expect(page).to have_css('.anpi-post .title', text: item.name)
      expect(page).to have_css('.anpi-post .body', text: item.text.split("\n")[0])
      expect(page).to have_css('.anpi-post .date', text: I18n.l(item.updated, format: :long))
      expect(page).to have_css('.anpi-post .kana', text: item.kana)
      expect(page).to have_css('.anpi-post .addr', text: item.addr)
      expect(page).to have_css('.anpi-post .sex', text: I18n.t("member.options.sex.#{item.sex}"))
      expect(page).to have_css('.anpi-post .age', text: item.age)
      expect(page).to have_css('.anpi-post .member', text: item.member.name)
    end

    it 'by age' do
      visit node.url
      fill_in 'keyword', with: item.age
      click_on '人を探す'

      expect(page).to have_css('.anpi-post .title', text: item.name)
      expect(page).to have_css('.anpi-post .body', text: item.text.split("\n")[0])
      expect(page).to have_css('.anpi-post .date', text: I18n.l(item.updated, format: :long))
      expect(page).to have_css('.anpi-post .kana', text: item.kana)
      expect(page).to have_css('.anpi-post .addr', text: item.addr)
      expect(page).to have_css('.anpi-post .sex', text: I18n.t("member.options.sex.#{item.sex}"))
      expect(page).to have_css('.anpi-post .age', text: item.age)
      expect(page).to have_css('.anpi-post .member', text: item.member.name)
    end

    it 'by email' do
      visit node.url
      fill_in 'keyword', with: item.email
      click_on '人を探す'

      expect(page).to have_css('.anpi-post .title', text: item.name)
      expect(page).to have_css('.anpi-post .body', text: item.text.split("\n")[0])
      expect(page).to have_css('.anpi-post .date', text: I18n.l(item.updated, format: :long))
      expect(page).to have_css('.anpi-post .kana', text: item.kana)
      expect(page).to have_css('.anpi-post .addr', text: item.addr)
      expect(page).to have_css('.anpi-post .sex', text: I18n.t("member.options.sex.#{item.sex}"))
      expect(page).to have_css('.anpi-post .age', text: item.age)
      expect(page).to have_css('.anpi-post .member', text: item.member.name)
    end
  end

  context 'search private post' do
    let!(:item) do
      create :board_anpi_post, cur_site: site, cur_member: member, text: "#{unique_id}\n#{unique_id}", public_scope: 'group'
    end

    it 'by name' do
      visit node.url
      fill_in 'keyword', with: item.name
      click_on '人を探す'

      expect(page).not_to have_css('.anpi-post')
    end
  end
end
