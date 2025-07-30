require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20240729000000_check_links_permissions.rb")

RSpec.describe SS::Migration20240729000000, dbscope: :example do
  let!(:role1) { create :cms_role }
  let!(:role2) { create :cms_role }
  let!(:role3) { create :cms_role_admin }

  let(:old_permissions) do
    %w(
      read_cms_check_links_reports
      delete_cms_check_links_reports
      read_other_cms_check_links_errors
      read_private_cms_check_links_errors
      edit_cms_check_links_ignore_urls)
  end
  let(:new_permissions) do
    %w(use_cms_check_links run_cms_check_links)
  end

  it do
    role2.permissions = (role2.permissions + old_permissions - new_permissions).uniq
    role2.update!

    role3.permissions = (role3.permissions + old_permissions - new_permissions).uniq
    role3.update!

    expect(role1.permissions).not_to include "read_cms_check_links_reports"
    expect(role1.permissions).not_to include "delete_cms_check_links_reports"
    expect(role1.permissions).not_to include "read_other_cms_check_links_errors"
    expect(role1.permissions).not_to include "read_private_cms_check_links_errors"
    expect(role1.permissions).not_to include "edit_cms_check_links_ignore_urls"
    expect(role1.permissions).not_to include "use_cms_tools"
    expect(role1.permissions).not_to include "use_cms_check_links"
    expect(role1.permissions).not_to include "run_cms_check_links"

    expect(role2.permissions).to include "read_cms_check_links_reports"
    expect(role2.permissions).to include "delete_cms_check_links_reports"
    expect(role2.permissions).to include "read_other_cms_check_links_errors"
    expect(role2.permissions).to include "read_private_cms_check_links_errors"
    expect(role2.permissions).to include "edit_cms_check_links_ignore_urls"
    expect(role2.permissions).not_to include "use_cms_tools"
    expect(role2.permissions).not_to include "use_cms_check_links"
    expect(role2.permissions).not_to include "run_cms_check_links"

    expect(role3.permissions).to include "read_cms_check_links_reports"
    expect(role3.permissions).to include "delete_cms_check_links_reports"
    expect(role3.permissions).to include "read_other_cms_check_links_errors"
    expect(role3.permissions).to include "read_private_cms_check_links_errors"
    expect(role3.permissions).to include "edit_cms_check_links_ignore_urls"
    expect(role3.permissions).to include "use_cms_tools"
    expect(role3.permissions).not_to include "use_cms_check_links"
    expect(role3.permissions).not_to include "run_cms_check_links"

    described_class.new.change

    role1.reload
    role2.reload
    role3.reload

    expect(role1.permissions).not_to include "read_cms_check_links_reports"
    expect(role1.permissions).not_to include "delete_cms_check_links_reports"
    expect(role1.permissions).not_to include "read_other_cms_check_links_errors"
    expect(role1.permissions).not_to include "read_private_cms_check_links_errors"
    expect(role1.permissions).not_to include "edit_cms_check_links_ignore_urls"
    expect(role1.permissions).not_to include "use_cms_tools"
    expect(role1.permissions).not_to include "use_cms_check_links"
    expect(role1.permissions).not_to include "run_cms_check_links"

    expect(role2.permissions).to include "read_cms_check_links_reports"
    expect(role2.permissions).to include "delete_cms_check_links_reports"
    expect(role2.permissions).to include "read_other_cms_check_links_errors"
    expect(role2.permissions).to include "read_private_cms_check_links_errors"
    expect(role2.permissions).to include "edit_cms_check_links_ignore_urls"
    expect(role2.permissions).not_to include "use_cms_tools"
    expect(role2.permissions).to include "use_cms_check_links"
    expect(role2.permissions).not_to include "run_cms_check_links"

    expect(role3.permissions).to include "read_cms_check_links_reports"
    expect(role3.permissions).to include "delete_cms_check_links_reports"
    expect(role3.permissions).to include "read_other_cms_check_links_errors"
    expect(role3.permissions).to include "read_private_cms_check_links_errors"
    expect(role3.permissions).to include "edit_cms_check_links_ignore_urls"
    expect(role3.permissions).to include "use_cms_tools"
    expect(role3.permissions).to include "use_cms_check_links"
    expect(role3.permissions).to include "run_cms_check_links"
  end
end
