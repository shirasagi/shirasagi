require 'spec_helper'

describe 'members/agents/nodes/my_photo', type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node_photo) { create :member_node_photo, cur_site: site, layout_id: layout.id }
  let(:node_mypage) { create :member_node_mypage, cur_site: site, layout_id: layout.id }
  let(:node_my_photo) { create :member_node_my_photo, cur_site: site, cur_node: node_mypage, layout_id: layout.id }
  let!(:node_login) do
    create(
      :member_node_login,
      cur_site: site,
      layout_id: layout.id,
      form_auth: 'enabled',
      redirect_url: node_my_photo.url)
  end
  let(:index_url) { node_my_photo.full_url }

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

    describe 'create new photo' do
      let(:photo_name) { unique_id }
      let(:photo_image) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

      it do
        visit index_url
        click_link '新規投稿'

        within 'form div.member-photo-page' do
          fill_in 'item[name]', with: photo_name
          attach_file 'item[in_image]', photo_image

          click_button I18n.t('ss.buttons.save')
        end

        expect(Member::Photo.site(site).count).to eq 1
        photo_page = Member::Photo.site(site).first
        expect(photo_page.name).to eq photo_name
        expect(photo_page.state).to eq 'public'

        expect(page).to have_css('table.member-photo-page tbody .name', text: photo_name)
        expect(page).to have_css('table.member-photo-page tbody .updated', text: I18n.l(photo_page.updated, format: :long))
        expect(page).to have_css('table.member-photo-page tbody .released', text: I18n.l(photo_page.released, format: :long))
        expect(page).to have_css('table.member-photo-page tbody .state', text: photo_page.label(:state))

        click_link photo_name

        expect(page).to have_css('.member-photo-page .name dd', text: photo_name)
        expect(page).to have_css('.member-photo-page .photo-body dd')
        expect(page).to have_css('.member-photo-page .state dd', text: photo_page.label(:state))

        #
        # 公開側を確認してみる
        #

        visit node_photo.full_url
        expect(page).to have_css('.photo .title', text: photo_name)

        page.find('.photo a').click
        expect(page).to have_css('.photo-body .contributor', text: cms_member.name)

        #
        # 削除
        #
        visit index_url
        click_link photo_name
        click_link I18n.t('ss.links.delete')

        within 'form div.member-photo-page' do
          expect(page).to have_css('.column dd', text: photo_name)

          click_button I18n.t('ss.buttons.delete')
        end

        expect(Member::Photo.site(site).count).to eq 0
      end

      context 'with workflow' do
        let(:item) do
          create :member_photo, cur_site: site, cur_node: node_mypage, layout_id: layout.id, state: 'closed',
                 workflow_state: 'request',
                 workflow_approvers: [{"level"=>1, "user_id"=>cms_user.id, state: 'request'}],
                 workflow_required_counts: [false]
        end

        it '#edit' do
          visit File.join(node_my_photo.full_url, item.id.to_s, 'edit')
          within 'form div.member-photo-page' do
            select I18n.t('ss.options.state.public'), from: 'item[state]'
            click_button I18n.t('ss.buttons.save')
          end
          photo_page = Member::Photo.site(site).first
          expect(photo_page.workflow_state).to be_nil
          expect(photo_page.workflow_approvers).to eq []
          expect(photo_page.workflow_required_counts).to eq []
        end
      end
    end
  end
end
