require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:folder) { create(:gws_notice_folder) }
  let!(:file) { tmp_ss_file(contents: 'temp_file', user: user) }
  let!(:item) do
    create(
      :gws_notice_post, cur_site: site, cur_user: user, folder: folder, user_ids: [user.id], file_ids: [file.id]
    )
  end

  before do
    login_gws_user
  end

  describe '#print' do
    it do
      visit gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      click_on item.name
      click_on I18n.t("ss.links.print")

      within ".print-preview.vertical" do
        expect(page).to have_css(".subject", text: item.name)
      end
    end
  end
end
