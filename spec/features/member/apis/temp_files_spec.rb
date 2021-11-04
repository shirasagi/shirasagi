require 'spec_helper'

describe "member_apis_temp_files", type: :feature, dbscope: :example, js: true do
  let(:member) { cms_member }
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node_blog) { create :member_node_blog, cur_site: site, layout_id: layout.id }
  let(:node_mypage) { create :member_node_mypage, cur_site: site, layout_id: layout.id }
  let(:node_my_blog) { create(:member_node_my_blog, cur_site: site, cur_node: node_mypage, layout_id: layout.id) }
  let!(:node_login) do
    create(
      :member_node_login,
      cur_site: site,
      layout_id: layout.id,
      form_auth: 'enabled',
      redirect_url: node_my_blog.url)
  end
  let!(:blog_layout) { create :member_blog_layout, cur_site: site, cur_node: node_blog }

  before do
    login_member(site, node_login)
  end

  after do
    logout_member(site, node_login)
  end

  context "sanitizer setting" do
    before { upload_policy_before_settings("sanitizer") }

    after { upload_policy_after_settings }

    it do
      # create
      visit member_apis_temp_files_path(member)
      attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      click_button I18n.t("ss.buttons.save")

      expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

      file = Member::TempFile.all.first
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exist?(file.path)).to be_truthy
      expect(Fs.exist?(file.sanitizer_input_path)).to be_truthy
      expect(Fs.cmp(file.path, file.sanitizer_input_path)).to be_truthy

      # restore
      restored_file = mock_sanitizer_restore(file)
      expect(restored_file.sanitizer_state).to eq 'complete'
      expect(Fs.exist?(restored_file.path)).to be_truthy
    end
  end

  context "restricted setting" do
    before do
      upload_policy_before_settings('sanitizer')
      site.set(upload_policy: 'restricted')
    end

    after { upload_policy_after_settings }

    it do
      # create
      visit member_apis_temp_files_path(member)
      attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      click_button I18n.t("ss.buttons.save")

      expect(page).to have_no_css('.file-view', text: 'keyvisual.jpg')

      file = Member::TempFile.all.first
      expect(file).to be_nil
    end
  end
end
