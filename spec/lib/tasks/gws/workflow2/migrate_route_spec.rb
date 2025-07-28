require 'spec_helper'

describe Tasks::Gws::Workflow2, dbscope: :example do
  describe ".migrate_route" do
    let!(:site) { gws_site }
    let!(:admin) { gws_user }
    let!(:user1) { create(:gws_user, group_ids: admin.group_ids, gws_role_ids: admin.gws_role_ids) }

    let!(:route1) do
      create(
        :gws_workflow_route, cur_site: site, name: unique_id, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_id" => user1.id, "editable" => 1 }
        ],
        required_counts: [ false ], approver_attachment_uses: %w(enabled),
        circulations: [], circulation_attachment_uses: []
      )
    end

    it do
      expect { described_class.migrate_route }.to output.to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Workflow2::Route.all.count).to eq 1
    end
  end
end
