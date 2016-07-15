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
  let(:text0) { unique_id }
  let(:text1) { unique_id }

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

    describe 'basic myself anpi crud' do
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
          fill_in 'item[text]', with: text0
          click_button '保存'
        end

        expect(current_path).to eq index_url
        expect(status_code).to eq 200

        within 'table.member-anpi-post' do
          expect(page).to have_css('td.name a', text: cms_member.name)
          expect(page).to have_css('td.text', text: text0)
          expect(page).to have_css('td.register', text: cms_member.name)
          expect(page).to have_css('td.datetime')
        end

        expect(Board::AnpiPost.count).to eq 1
        Board::AnpiPost.first.tap do |anpi|
          expect(anpi.name).to eq cms_member.name
          expect(anpi.member_id).to eq cms_member.id
        end

        click_on cms_member.name
        click_on '編集する'
        within 'form.member-anpi-post-page' do
          fill_in 'item[text]', with: text1
          click_button '保存'
        end

        within 'table.member-anpi-post' do
          expect(page).to have_css('td.name a', text: cms_member.name)
          expect(page).to have_css('td.text', text: text1)
          expect(page).to have_css('td.register', text: cms_member.name)
          expect(page).to have_css('td.datetime')
        end

        click_on cms_member.name
        click_on '削除する'
        click_on '削除'
        expect(page).not_to have_css('table.member-anpi-post')

        expect(Board::AnpiPost.count).to eq 0
      end
    end

    describe 'basic other anpi crud' do
      let(:name) { unique_id }

      it do
        visit index_url
        expect(current_path).to eq index_url
        expect(status_code).to eq 200

        click_link '未登録者安否作成'

        within 'form.member-anpi-post-page' do
          fill_in 'item[name]', with: name
          fill_in 'item[text]', with: text0
          click_button '保存'
        end

        expect(current_path).to eq index_url
        expect(status_code).to eq 200

        within 'table.member-anpi-post' do
          expect(page).to have_css('td.name a', text: name)
          expect(page).to have_css('td.text', text: text0)
          expect(page).to have_css('td.register', text: cms_member.name)
          expect(page).to have_css('td.datetime')
        end

        expect(Board::AnpiPost.count).to eq 1
        Board::AnpiPost.first.tap do |anpi|
          expect(anpi.name).to eq name
          expect(anpi.member_id).to eq cms_member.id
        end

        click_on name
        click_on '編集する'
        within 'form.member-anpi-post-page' do
          fill_in 'item[text]', with: text1
          click_button '保存'
        end

        within 'table.member-anpi-post' do
          expect(page).to have_css('td.name a', text: name)
          expect(page).to have_css('td.text', text: text1)
          expect(page).to have_css('td.register', text: cms_member.name)
          expect(page).to have_css('td.datetime')
        end

        click_on name
        click_on '削除する'
        click_on '削除'
        expect(page).not_to have_css('table.member-anpi-post')

        expect(Board::AnpiPost.count).to eq 0
      end
    end

    describe 'map view with group' do
      let(:member0) { cms_member }
      let(:member1) do
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
      let(:group_name) { unique_id }

      before do
        group = Member::Group.create cur_site: site, name: group_name, invitation_message: unique_id,
                                     in_admin_member_ids: [ member0.id ]
        group.members.new(member_id: member1.id, state: 'user')
        group.save!

        create :board_anpi_post, cur_site: site, cur_member: member0
        create :board_anpi_post, cur_site: site, cur_member: member1

        node_my_anpi_post.map_state = 'enabled'
        node_my_anpi_post.map_view_state = 'enabled'
        node_my_anpi_post.save!
      end

      it do
        visit index_url
        expect(page).to have_css('form.search')
        expect(page).to have_css('table.member-anpi-post tbody tr', count: 2)

        click_on '地図表示'
        expect(page).to have_css('#marker-html-1', visible: false)
        expect(page).to have_css('#marker-html-2', visible: false)
      end
    end
  end
end
