require 'spec_helper'

describe 'members/agents/nodes/my_anpi_post', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_mypage) { create :member_node_mypage, cur_site: site, layout_id: layout.id }
  let(:node_my_anpi_post) { create :member_node_my_anpi_post, cur_site: site, cur_node: node_mypage, layout_id: layout.id }
  let!(:node_login) do
    create(
      :member_node_login,
      cur_site: site,
      layout_id: layout.id,
      form_auth: 'enabled',
      redirect_url: node_my_anpi_post.url)
  end
  let(:index_url) { node_my_anpi_post.url }
  let(:text) { unique_id }

  describe 'without member login' do
    it do
      visit index_url

      within 'form.form-login' do
        expect(page).to have_css('input#item_email')
        expect(page).to have_css('input#item_password')
      end
    end
  end

  describe 'with member login' do
    before do
      login_member(site, node_login)
    end

    after do
      logout_member(site, node_login)
    end

    describe '一人ぼっちの安否登録' do
      it do
        visit index_url
        expect(current_path).to eq index_url
        expect(status_code).to eq 200

        click_link '新規作成'

        # check pre-filled field
        within 'form.member-anpi-post-page' do
          expect(page).to have_field('item[name]', with: cms_member.name)
        end

        within 'form.member-anpi-post-page' do
          fill_in 'item[text]', with: text
          click_button '保存'
        end

        expect(current_path).to eq index_url
        expect(status_code).to eq 200

        within 'table.member-anpi-post' do
          expect(page).to have_css('td.name a', text: cms_member.name)
          expect(page).to have_css('td.text', text: text)
          expect(page).to have_css('td.register', text: cms_member.name)
          expect(page).to have_css('td.datetime')
        end
      end
    end

    describe '一人ぼっちの未登録者安否登録' do
      let(:name) { unique_id }

      it do
        visit index_url
        expect(current_path).to eq index_url
        expect(status_code).to eq 200

        click_link '未登録者安否作成'

        within 'form.member-anpi-post-page' do
          fill_in 'item[name]', with: name
          fill_in 'item[text]', with: text
          click_button '保存'
        end

        expect(current_path).to eq index_url
        expect(status_code).to eq 200

        within 'table.member-anpi-post' do
          expect(page).to have_css('td.name a', text: name)
          expect(page).to have_css('td.text', text: text)
          expect(page).to have_css('td.register', text: cms_member.name)
          expect(page).to have_css('td.datetime')
        end
      end
    end
  end
end
