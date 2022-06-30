require 'spec_helper'

describe Event::Page::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group) do
    name = 'シラサギ市/企画政策部/政策課'
    Cms::Group.where(name: name).first_or_create!(attributes_for(:cms_group, name: name))
  end
  let!(:layout) { create(:cms_layout, site: site, name: "イベントカレンダー") }
  let!(:node) { create(:event_node_page, site: site, filename: "calendar", group_ids: [ group.id ]) }
  let(:role) { create(:cms_role_admin, site_id: site.id, permissions: %w(import_private_event_pages)) }
  let(:user) { create(:cms_user, uid: unique_id, name: unique_id, group_ids: [ group.id ], role: role) }

  let!(:ss_file) { tmp_ss_file contents: "", basename: "event_pages.csv" }

  describe ".perform_later" do
    context "with node" do
      let(:basename) { "page1.html" }
      let(:name) { "住民相談会を開催します。" }
      let(:schedule) { "〇〇年○月〇日" }
      let(:venue) { "○○○○○○○○○○" }
      let(:content) { "○○○○○○○○○○○○○○○○○○○○" }
      let(:cost) { "○○○○○○○○○○" }
      let(:related_url) { "http://demo.ss-proj.org/" }
      let(:event_name) { "住民相談会" }
      let(:event_recurrence) do
        { kind: "date", start_at: "2016/09/07", frequency: "daily", until_on: "2016/09/27" }
      end
      let(:event_deadline) { "2016/8/13" }
      let(:released_type) { "fixed" }
      let(:released) { "2016/09/07 19:11" }
      let(:state) { "closed" }
      let(:event_dates) do
        Range.new(event_recurrence[:start_at].in_time_zone.to_date, event_recurrence[:until_on].in_time_zone.to_date).to_a
      end

      before do
        template_event_node = create(:event_node_page, cur_site: site)
        create(
          :event_page, cur_site: site, cur_node: template_event_node, layout: layout, basename: basename, name: name,
          schedule: schedule, venue: venue, content: content, cost: cost, related_url: related_url,
          event_name: event_name, event_recurrences: [ event_recurrence ], event_deadline: event_deadline,
          released_type: released_type, released: released, state: state, group_ids: [ group.id ]
        )

        criteria = Event::Page.site(site).node(template_event_node)
        exporter = Cms::PageExporter.new(mode: "event", site: @cur_site, criteria: criteria)
        enumerable = exporter.enum_csv(encoding: "Shift_JIS")

        ::File.open(ss_file.path, "wb") do |f|
          enumerable.each { |csv| f.write(csv) }
        end

        job_class = described_class.bind(site_id: site, node_id: node, user_id: user)
        expect { job_class.perform_now(ss_file.id) }.to output(include("import start event_pages.csv\n")).to_stdout
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        items = Event::Page.site(site).where(filename: /^#{node.filename}\//, depth: 2)
        expect(items.count).to be 1

        item = items.where(filename: "#{node.filename}/#{basename}").first
        expect(item.name).to eq name
        expect(item.layout.try(:name)).to eq layout.name
        expect(item.order).to eq 0

        expect(item.schedule).to eq schedule
        expect(item.venue).to eq venue
        expect(item.content).to eq content
        expect(item.cost).to eq cost
        expect(item.related_url).to eq related_url
        expect(item.event_name).to eq event_name
        expect(item.event_dates).to eq event_dates
        expect(item.event_deadline).to eq event_deadline.in_time_zone
        expect(item.released_type).to eq released_type
        expect(item.released).to eq released.in_time_zone
        expect(item.groups.pluck(:name)).to match_array [ group.name ]
        unless SS.config.ss.disable_permission_level
          expect(item.permission_level).to be 2
        end
        expect(item.state).to eq state
      end
    end
  end
end
