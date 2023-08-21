require 'spec_helper'

describe "gws_workflow_files", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_workflow_files_path(site, state: 'all') }

  it do
    visit index_path
    expect(page).to have_css('form[action="/.mypage/login"]')
  end
end
