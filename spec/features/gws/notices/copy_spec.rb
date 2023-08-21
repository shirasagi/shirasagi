require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user1) { gws_user }
  let(:user2) { create(:gws_user, :gws_user_base) }
  let(:folder) { create(:gws_notice_folder) }
  let!(:file) { tmp_ss_file(contents: 'temp_file', user: user1) }
  let!(:item) do
    create(
      :gws_notice_post,
      cur_site: site,
      cur_user: user1,
      user: user2,
      folder: folder,
      comment_state: 'disabled',
      readable_setting_range: 'public',
      user_ids: [user1.id, user2.id],
      severity: 'high',
      links: [{ name: 'sample', url: 'http://sample.jp', target: '' }],
      file_ids: [file.id]
    )
  end
  let(:copy_path) { copy_gws_notice_editable_path(site: site, folder_id: folder, category_id: '-', id: item.id) }
  let(:show_path) { gws_notice_editable_path(site: site, folder_id: folder, category_id: '-', id: item.id) }
  let(:admin_index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }

  describe 'auth' do
    context 'login user is editable' do
      before { login_user user1 }

      it 'status code is 200' do
        visit copy_path
        expect(status_code).to eq 200
      end
    end

    context 'login user is not editable' do
      let(:user3) { create(:gws_user, :gws_user_base) }

      before { login_user user3 }

      it 'status code is 404' do
        visit copy_path
        expect(status_code).to eq 404
      end
    end
  end

  describe "screen transition" do
    before do
      login_gws_user
      visit show_path
    end

    it do
      click_link I18n.t('ss.links.copy')
      expect(current_path).to eq copy_path

      click_link I18n.t('ss.links.back_to_index')
      expect(current_path).to eq admin_index_path
    end
  end

  describe 'copy', js: true do
    let(:copied_item) { Gws::Notice::Post.last }

    before do
      login_gws_user
      visit copy_path
    end

    it 'should be copied properly' do
      expect do
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
      end.to change { Gws::Notice::Post.count }.by(1)
        .and change { SS::File.count }.by(1)

      expect(copied_item.name).to eq I18n.t('gws/notice.prefix.copy') + item.name
      expect(copied_item.text).to eq item.text
      expect(copied_item.site).to eq site
      expect(copied_item.folder).to eq folder
      expect(copied_item.user).to eq user1
      expect(copied_item.comment_state).to eq 'disabled'
      expect(copied_item.readable_setting_range).to eq 'public'
      expect(copied_item.severity).to eq 'high'
      expect(copied_item.links).to eq [{ 'name' => 'sample', 'url' => 'http://sample.jp', 'target' => '' }]
      expect(copied_item.user_ids).to match_array [user1.id, user2.id]
      expect(copied_item.total_file_size).to eq item.total_file_size
      expect(copied_item.file_ids).not_to eq item.file_ids
    end
  end
end
