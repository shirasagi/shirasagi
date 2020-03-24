require 'spec_helper'

describe Event::Ical::ImportJob, dbscope: :example do
  let(:url) { "http://#{unique_id}.example.jp/#{unique_id}.ics" }
  let(:site) { cms_site }
  let(:cate) { create :category_node_page, site: site }
  let(:node) do
    create :event_node_page, site: site, ical_refresh_method: 'auto', ical_import_url: url, ical_category_ids: [ cate.id ]
  end
  let(:user) { cms_user }
  let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

  around do |example|
    Timecop.travel("2018/08/28") do
      example.run
    end
  end

  after { WebMock.reset! }

  context "when importing ics with http success" do
    before do
      WebMock.reset!

      body = ::File.read(Rails.root.join("spec", "fixtures", "event", "ical", path))
      stub_request(:get, node.ical_import_url).
        to_return(status: 200, body: body, headers: {})
    end

    context "with regular shirasagi format" do
      let(:path) { "event-1.ics" }

      it do
        expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(2) &
                                                                 output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        Event::Page.site(site).node(node).find_by(ical_uid: 'doc-1').tap do |doc|
          expect(doc.name).to eq "Python 夏休み集中キャンプ"
          expect(doc.category_ids).to eq [ cate.id ]
          expect(doc.event_name).to eq doc.name
          expect(doc.content).to eq "夏休み最後の週に Python の集中キャンプを実施します。"
          expect(doc.summary_html).to eq doc.content
          expect(doc.venue).to eq "教育会館"
          expect(doc.contact).to eq "Python 普及委員会"
          expect(doc.schedule).to eq "8月27日〜8月31日"
          expect(doc.related_url).to eq "http://www.example.jp/sabd/"
          expect(doc.cost).to eq "2,000円"
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/29", "2018/08/30", "2018/08/31")
        end
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present
        Event::Page.site(site).node(node).find_by(ical_uid: 'doc-2').tap do |doc|
          expect(doc.name).to eq "SUMMARY-○○○○○○○○○○"
          expect(doc.category_ids).to eq [ cate.id ]
          expect(doc.event_name).to eq doc.name
          expect(doc.content).to eq "DESCRIPTION-○○○○○○○○○○"
          expect(doc.summary_html).to eq doc.content
          expect(doc.venue).to eq "LOCATION-○○○○○○○○○○"
          expect(doc.contact).to eq "CONTACT-○○○○○○○○○○"
          expect(doc.schedule).to eq "SCHEDULE-〇〇年○月〇日"
          expect(doc.related_url).to eq "http://organizer.example.jp/x/y/z/"
          expect(doc.cost).to eq "COST-○○○○○○○○○○"
          expect(doc.event_dates).to include("2018/07/30", "2018/07/31", "2018/08/01", "2018/08/02", "2018/08/03")
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/29", "2018/08/30", "2018/08/31")
          expect(doc.event_dates).to include("2018/09/24", "2018/09/25", "2018/09/26", "2018/09/27", "2018/09/28")
        end
      end
    end

    context "with rdate as period" do
      let(:path) { "event-2.ics" }

      it do
        expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(2) &
                                                                 output(include("there are 1 calendars.\n")).to_stdout
        Event::Page.site(site).node(node).find_by(ical_uid: 'doc-2').tap do |doc|
          expect(doc.event_dates).to include("2018/07/30", "2018/07/31", "2018/08/01", "2018/08/02", "2018/08/03")
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/29", "2018/08/30", "2018/08/31")
          expect(doc.event_dates).to include("2018/09/24", "2018/09/25", "2018/09/26", "2018/09/27", "2018/09/28")
        end
      end
    end

    context "ical_refresh_method is auto" do
      let(:path) { "event-1.ics" }
      let!(:node) { create :event_node_page, site: site, ical_refresh_method: 'auto', ical_import_url: url }

      it do
        expect { described_class.perform_jobs(site, user) }.to output(include("there are 1 calendars.\n")).to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end
      end
    end

    context "ical_refresh_method is manual" do
      let(:path) { "event-1.ics" }
      let!(:node) { create :event_node_page, site: site, ical_refresh_method: 'manual', ical_import_url: url }

      it do
        described_class.perform_jobs(site, user)
        expect(Job::Log.count).to eq 0
      end
    end

    context "when ical_max_docs is 1" do
      let(:path) { "event-1.ics" }
      let(:node) { create :event_node_page, site: site, ical_refresh_method: 'auto', ical_import_url: url, ical_max_docs: 1 }

      it do
        expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(1) &
                                                                 output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_blank
      end
    end

    context "when ical is not changed" do
      let(:path) { "event-1.ics" }

      it do
        expect { described_class.bind(bindings).perform_now }.to output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.count).to eq 2

        expect { described_class.bind(bindings).perform_now }.to output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.count).to eq 2

        doc1 = Event::Page.site(site).node(node).where(ical_uid: 'doc-1').first
        expect(doc1.name).to eq "Python 夏休み集中キャンプ"
        doc2 = Event::Page.site(site).node(node).where(ical_uid: 'doc-2').first
        expect(doc2.name).to eq "SUMMARY-○○○○○○○○○○"
      end
    end

    context "when importing ics with exdate" do
      let(:path) { "event-exdate-1.ics" }

      it do
        expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(1) &
                                                                 output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        Event::Page.site(site).node(node).find_by(ical_uid: 'doc-1').tap do |doc|
          expect(doc.name).to eq "Python 夏休み集中キャンプ"
          expect(doc.event_name).to eq doc.name
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/30", "2018/08/31")
          expect(doc.event_dates).not_to include("2018/08/29")
        end
      end
    end

    context "when importing ics with rrule" do
      context "daily" do
        let(:path) { "event-rrule-1.ics" }

        it do
          expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(3) &
                                                                   output(include("there are 1 calendars.\n")).to_stdout

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-1').tap do |doc|
            expect(doc.name).to eq "event 1"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to eq %w(2018/08/27 2018/08/28 2018/08/29 2018/08/30 2018/08/31).join("\r\n")
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-2').tap do |doc|
            expect(doc.name).to eq "event 2"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to eq %w(2018/08/27 2018/08/28 2018/08/29 2018/08/30 2018/08/31 2018/09/01).join("\r\n")
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-3')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-3').tap do |doc|
            expect(doc.name).to eq "event 3"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to start_with("2018/08/27\r\n")
            expect(doc.event_dates).to end_with("\r\n2019/02/22")
          end
        end
      end

      context "weekly" do
        let(:path) { "event-rrule-2.ics" }

        it do
          expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(3) &
                                                                   output(include("there are 1 calendars.\n")).to_stdout

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-1').tap do |doc|
            expect(doc.name).to eq "event 1"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to eq %w(2018/08/27 2018/09/02 2018/09/03 2018/09/09 2018/09/10).join("\r\n")
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-2').tap do |doc|
            expect(doc.name).to eq "event 2"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to eq %w(2018/08/27 2018/08/28 2018/08/29).join("\r\n")
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-3')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-3').tap do |doc|
            expect(doc.name).to eq "event 3"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to start_with("2018/08/27\r\n")
            expect(doc.event_dates).to end_with("\r\n2019/02/22")
          end
        end
      end

      context "monthly" do
        let(:path) { "event-rrule-3.ics" }

        it do
          expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(6) &
                                                                   output(include("there are 1 calendars.\n")).to_stdout

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-1').tap do |doc|
            expect(doc.name).to eq "event 1"
            expect(doc.event_name).to eq doc.name
            dates = %w(2018/09/15 2018/10/01 2018/10/02 2018/10/03 2018/10/04 2018/10/05 2018/10/06 2018/10/07)
            expect(doc.event_dates).to eq dates.join("\r\n")
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-2').tap do |doc|
            expect(doc.name).to eq "event 2"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to eq %w(2018/09/15 2018/09/29 2018/09/30).join("\r\n")
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-3')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-3').tap do |doc|
            expect(doc.name).to eq "event 3"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to start_with(%w(2018/09/15 2018/09/16 2018/09/17).join("\r\n"))
            expect(doc.event_dates).to end_with(%w(2018/10/13 2018/10/14 2018/10/15).join("\r\n"))
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-4')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-4').tap do |doc|
            expect(doc.name).to eq "event 4"
            expect(doc.event_name).to eq doc.name
            dates = %w(2018/09/15 2018/09/24 2018/09/25 2018/09/26 2018/09/27 2018/09/28 2018/09/29 2018/09/30)
            expect(doc.event_dates).to eq dates.join("\r\n")
          end

          # doc-5 の動作は Thunderbird と Google Calendar とで異なる。ここでは Google Calendar に合わせる。
          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-5')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-5').tap do |doc|
            expect(doc.name).to eq "event 5"
            expect(doc.event_name).to eq doc.name
            expect(doc.event_dates).to eq %w(2018/09/15 2019/01/31 2019/03/31 2019/05/31 2019/07/31).join("\r\n")
          end

          expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-6')).to be_present
          Event::Page.site(site).node(node).find_by(ical_uid: 'doc-6').tap do |doc|
            expect(doc.name).to eq "event 6"
            expect(doc.event_name).to eq doc.name
            dates = %w(2018/09/15 2018/09/30 2018/10/31 2018/11/30 2018/12/31 2019/01/31 2019/02/28 2019/03/31
                       2019/04/30 2019/05/31 2019/06/30 2019/07/31 2019/08/31)
            expect(doc.event_dates).to eq dates.join("\r\n")
          end
        end
      end
    end
  end

  context "when ical is updated" do
    context "in second try, there is no doc-2" do
      before do
        WebMock.reset!

        body1 = ::File.read(Rails.root.join("spec", "fixtures", "event", "ical", "event-1.ics"))
        body2 = ::File.read(Rails.root.join("spec", "fixtures", "event", "ical", "updated_event.ics"))
        stub_request(:get, node.ical_import_url).
          to_return(status: 200, body: body1, headers: {}).then.
          to_return(status: 200, body: body2, headers: {})
      end

      after { travel_back }

      it do
        travel_to('2018-05-01 00:00')
        expect { described_class.bind(bindings).perform_now }.to output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.count).to eq 2
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present

        travel_to('2018-07-01 00:00')
        expect { described_class.bind(bindings).perform_now }.to output(include("update event/page")).to_stdout
        expect(Event::Page.count).to eq 1
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.where(ical_uid: 'doc-2')).to be_blank

        doc1 = Event::Page.site(site).node(node).where(ical_uid: 'doc-1').first
        expect(doc1.name).to eq 'new_doc1'
      end
    end

    context "in second try, there are no events" do
      before do
        WebMock.reset!

        body1 = ::File.read(Rails.root.join("spec", "fixtures", "event", "ical", "event-1.ics"))
        body2 = ::File.read(Rails.root.join("spec", "fixtures", "event", "ical", "event-empty.ics"))
        stub_request(:get, node.ical_import_url).
          to_return(status: 200, body: body1, headers: {}).then.
          to_return(status: 200, body: body2, headers: {})
      end

      it do
        expect { described_class.bind(bindings).perform_now }.to output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.count).to eq 2
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present

        expect { described_class.bind(bindings).perform_now }.to \
          output(include("there are no events in the calendar\n")).to_stdout
        expect(Event::Page.count).to eq 0
        expect(Event::Page.where(ical_uid: 'doc-1')).to be_blank
        expect(Event::Page.where(ical_uid: 'doc-2')).to be_blank
      end
    end

    context "in second try, timeout error occurs" do
      before do
        WebMock.reset!

        body1 = ::File.read(Rails.root.join("spec", "fixtures", "event", "ical", "event-1.ics"))
        stub_request(:get, node.ical_import_url).
          to_return(status: 200, body: body1, headers: {}).then.
          to_timeout
      end

      it do
        expect { described_class.bind(bindings).perform_now }.to output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.count).to eq 2
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present

        expect { described_class.bind(bindings).perform_now }.to output(include("-- Error\n", "execution expired\n")).to_stdout
        expect(Event::Page.count).to eq 2
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present
      end
    end

    context "in second try, 404 error occurs" do
      before do
        WebMock.reset!

        body1 = ::File.read(Rails.root.join("spec", "fixtures", "event", "ical", "event-1.ics"))
        stub_request(:get, node.ical_import_url).
          to_return(status: 200, body: body1, headers: {}).then.
          to_return(status: [ 404, "Not Found" ])
      end

      it do
        expect { described_class.bind(bindings).perform_now }.to output(include("there are 1 calendars.\n")).to_stdout
        expect(Event::Page.count).to eq 2
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present

        expect { described_class.bind(bindings).perform_now }.to output(include("-- Error\n", "404 Not Found\n")).to_stdout
        expect(Event::Page.count).to eq 2
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-1')).to be_present
        expect(Event::Page.site(site).node(node).where(ical_uid: 'doc-2')).to be_present
      end
    end
  end
end
