require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let(:resizing_width) { rand(300..400) }
  let(:resizing_height) { rand(200..300) }
  let(:multibyte_filename_state) { %w(enabled disabled).sample }
  let(:multibyte_filename_state_label) { I18n.t("ss.options.multibyte_filename_state.#{multibyte_filename_state}") }
  let(:access_restriction_state) { %w(enabled disabled).sample }
  let(:access_restriction_state_label) { I18n.t("ss.options.state.#{access_restriction_state}") }
  let(:basic_auth_id) { unique_id }
  let(:basic_auth_password) { unique_id }
  let(:env_key) { unique_id }
  let(:env_value) { unique_id }

  before { login_cms_user }

  it do
    visit cms_site_path(site: site)
    click_on I18n.t("ss.links.edit")

    within "form#item-form" do
      ensure_addon_opened("#addon-ss-agents-addons-file_setting")
      within "#addon-ss-agents-addons-file_setting" do
        fill_in "item[in_file_resizing_width]", with: resizing_width
        fill_in "item[in_file_resizing_height]", with: resizing_height
        select multibyte_filename_state_label, from: "item[multibyte_filename_state]"
        select access_restriction_state_label, from: "item[file_fs_access_restriction_state]"
        fill_in "item[file_fs_access_restriction_basic_auth_id]", with: basic_auth_id
        fill_in "item[in_file_fs_access_restriction_basic_auth_password]", with: basic_auth_password
        fill_in "item[file_fs_access_restriction_env_key]", with: env_key
        fill_in "item[file_fs_access_restriction_env_value]", with: env_value
      end

      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    site.reload
    expect(site.file_resizing).to eq [ resizing_width, resizing_height ]
    expect(site.multibyte_filename_state).to eq multibyte_filename_state
    expect(site.file_fs_access_restriction_state).to eq access_restriction_state
    expect(site.file_fs_access_restriction_basic_auth_id).to eq basic_auth_id
    expect(site.file_fs_access_restriction_basic_auth_password).to eq SS::Crypto.encrypt(basic_auth_password)
    expect(site.file_fs_access_restriction_env_key).to eq env_key
    expect(site.file_fs_access_restriction_env_value).to eq env_value
  end
end
