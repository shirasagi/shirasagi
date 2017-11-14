require 'spec_helper'

describe Service::Account do
  let(:admin) { create(:service_account_admin) }
  let(:item) { create(:service_account) }

  it "methods" do
    expect(item.admin?).to be_falsey
    expect(admin.admin?).to be_truthy

    expect(item.cms_enabled?).to be_truthy
    expect(item.gws_enabled?).to be_truthy
    expect(item.webmail_enabled?).to be_truthy

    # no quota
    expect(item.find_base_quota_used).to be 0
    expect(item.find_cms_quota_used).to be 0
    expect(item.find_gws_quota_used).to be 0
    expect(item.find_base_quota_used).to be 0

    # set quota
    item.cms_quota = 1
    item.gws_quota = 1
    item.webmail_quota = 1

    expect(item.cms_enabled?).to be_truthy
    expect(item.gws_enabled?).to be_truthy
    expect(item.webmail_enabled?).to be_truthy

    # use quota
    create(:cms_notice, cur_site: cms_site)
    create(:gws_notice, cur_site: gws_site)
    create(:webmail_signature, cur_user: gws_user)
    item.organization_ids = SS::Group.organizations.pluck(:id)
    item.reload_quota_used

    expect(item.base_quota_used).to be > 0
    expect(item.cms_quota_used).to be > 0
    expect(item.gws_quota_used).to be > 0
    expect(item.webmail_quota_used).to be > 0
    expect(item.cms_enabled?).to be_falsey
    expect(item.gws_enabled?).to be_falsey
    expect(item.webmail_enabled?).to be_falsey
  end
end
