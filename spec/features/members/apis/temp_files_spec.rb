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
    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
      Fs.mkdir_p(SS.config.ss.sanitizer_input)
      Fs.mkdir_p(SS.config.ss.sanitizer_output)
    end

    after do
      Fs.rm_rf(SS.config.ss.sanitizer_input)
      Fs.rm_rf(SS.config.ss.sanitizer_output)
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      # create
      visit member_apis_temp_files_path(member)
      attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      click_button I18n.t("ss.buttons.save")

      expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

      file = Member::TempFile.all.first
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exists?(file.path)).to be_truthy
      expect(Fs.exists?(file.sanitizer_input_path)).to be_truthy
      expect(FileTest.size(file.path)).to eq 2048

      # restore
      output_path = "#{SS.config.ss.sanitizer_output}/#{file.id}_filename_100_marked.#{file.extname}"
      Fs.mv file.sanitizer_input_path, output_path
      file.sanitizer_restore_file(output_path)
      expect(file.sanitizer_state).to eq 'complete'
      expect(FileTest.size(file.path)).to be > 2048
    end
  end

  context "restricted setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
      site.update_attributes(upload_policy: 'restricted')
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

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
