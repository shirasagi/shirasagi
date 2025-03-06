require 'spec_helper'

describe Gws::Elasticsearch::Setting::Board, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:item) { described_class.new(cur_site: site, cur_user: user) }
  let!(:custom_group) { create :gws_custom_group }

  describe 'filters' do
    it do
      # readable

      filter = item.readable_filter
      should = filter[:bool][:must][3][:bool][:should]
      expect(should[4][:bool][:must][0][:terms][:readable_custom_group_ids]).to include custom_group.id
      expect(should[5][:bool][:must][0][:terms][:member_custom_group_ids]).to include custom_group.id

      # manageable/other

      filter = item.manageable_filter[:bool][:should].to_json
      expect(filter).to include %({"term":{"user_ids":#{user.id}}})

      # manageable/private

      Gws::Role.each do |role|
        role.permissions = role.permissions.reject { |p| p.include?('_other_') }
        role.save
      end
      user.clear_gws_role_permissions

      filter = item.manageable_filter[:bool][:should].to_json
      expect(filter).to include %({"term":{"user_ids":#{user.id}}})
      expect(filter).to include %({"terms":{"group_ids":#{user.group_ids.to_json}}})

      # manageable/none

      Gws::Role.each do |role|
        role.permissions = role.permissions.reject { |p| p.include?('_private_') }
        role.save
      end
      user.clear_gws_role_permissions

      filter = item.manageable_filter[:bool][:should].to_json
      expect(filter).to include %({"term":{"user_ids":#{user.id}}})
    end
  end
end
