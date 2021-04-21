require 'spec_helper'

describe Rss::ImportWeatherXmlAllJob, dbscope: :example do
  let(:site1) { create :cms_site_unique }
  let!(:node1) { create(:rss_node_weather_xml, cur_site: site1, page_state: 'closed') }
  let(:site2) { create :cms_site_unique }
  let!(:node2) { create(:rss_node_weather_xml, cur_site: site2, page_state: 'closed') }
  let(:model) { Rss::WeatherXmlPage }
  let(:xml0) { File.read(Rails.root.join(*%w(spec fixtures jmaxml weather-sample.xml))) }
  let(:xml1) { File.read(Rails.root.join(*%w(spec fixtures jmaxml afeedc52-107a-3d1d-9196-b108234d6e0f.xml))) }
  let(:xml2) { File.read(Rails.root.join(*%w(spec fixtures jmaxml 2b441518-4e79-342c-a271-7c25597f3a69.xml))) }

  after(:all) do
    WebMock.reset!
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  around do |example|
    ::FileUtils.rm_rf(described_class.data_cache_dir) if described_class.data_cache_dir.present?

    perform_enqueued_jobs do
      example.run
    end
  end

  context "plain xml" do
    before do
      @stab_seed1 = stub_request(:get, 'http://weather.example.jp/developer/xml/feed/other.xml').
        to_return(body: xml0, status: 200, headers: { 'Content-Type' => 'application/xml' })
      stub_request(:get, 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').
        to_return(body: xml1, status: 200, headers: { 'Content-Type' => 'application/xml' })
      stub_request(:get, 'http://xml.kishou.go.jp/data/2b441518-4e79-342c-a271-7c25597f3a69.xml').
        to_return(body: xml2, status: 200, headers: { 'Content-Type' => 'application/xml' })
    end

    it do
      expect { described_class.perform_now }.to change { model.count }.from(0).to(4)

      item1 = model.site(site1).node(node1).where(rss_link: 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').first
      expect(item1).not_to be_nil
      expect(item1.name).to eq '気象警報・注意報'
      expect(item1.rss_link).to eq 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml'
      expect(item1.html).to eq '【福島県気象警報・注意報】注意報を解除します。'
      expect(item1.released).to eq Time.zone.parse('2016-03-10T09:22:41Z')
      expect(item1.authors.count).to eq 1
      expect(item1.authors.first.name).to eq '福島地方気象台'
      expect(item1.authors.first.email).to be_nil
      expect(item1.authors.first.uri).to be_nil
      expect(item1.event_id).to eq '20160318182200_984'
      expect(item1.weather_xml).not_to be_nil
      expect(item1.weather_xml).to include('<InfoKind>気象警報・注意報</InfoKind>')
      expect(item1.state).to eq 'closed'

      item2 = model.site(site2).node(node2).where(rss_link: 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').first
      expect(item2.name).to eq item1.name
      expect(item2.rss_link).to eq item1.rss_link

      expect(Job::Log.count).to eq 5
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(SS::Task.count).to eq 3
      expect(SS::Task.where(site_id: nil).count).to eq 1
      expect(SS::Task.where(site_id: site1.id).count).to eq 1
      expect(SS::Task.where(site_id: site2.id).count).to eq 1
      SS::Task.where(site_id: nil).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml_all"
        expect(task.state).to eq "stop"
        expect(task.interrupt).to be_blank
        expect(task.started).to be_present
        expect(task.closed).to be_present
      end
      SS::Task.where(site_id: site1.id).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml"
        expect(task.state).to eq "stop"
      end
      SS::Task.where(site_id: site2.id).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml"
        expect(task.state).to eq "stop"
      end

      expect(@stab_seed1).to have_been_requested.times(1)
    end
  end

  context "gzip-compressed xml" do
    before do
      @stab_seed1 = stub_request(:get, 'http://weather.example.jp/developer/xml/feed/other.xml').
        to_return(body: gzip(xml0), status: 200, headers: { 'Content-Encoding' => 'gzip', 'Content-Type' => 'application/xml' })
      stub_request(:get, 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').
        to_return(body: gzip(xml1), status: 200, headers: { 'Content-Encoding' => 'gzip', 'Content-Type' => 'application/xml' })
      stub_request(:get, 'http://xml.kishou.go.jp/data/2b441518-4e79-342c-a271-7c25597f3a69.xml').
        to_return(body: gzip(xml2), status: 200, headers: { 'Content-Encoding' => 'gzip', 'Content-Type' => 'application/xml' })
    end

    def gzip(text)
      file = tmpfile(binary: true) do |f|
        Zlib::GzipWriter.open(f) do |gz|
          gz.write(text)
        end
      end

      ::File.binread(file)
    end

    it do
      expect { described_class.perform_now }.to change { model.count }.from(0).to(4)

      item1 = model.site(site1).node(node1).where(rss_link: 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').first
      expect(item1).not_to be_nil
      expect(item1.name).to eq '気象警報・注意報'
      expect(item1.rss_link).to eq 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml'
      expect(item1.html).to eq '【福島県気象警報・注意報】注意報を解除します。'
      expect(item1.released).to eq Time.zone.parse('2016-03-10T09:22:41Z')
      expect(item1.authors.count).to eq 1
      expect(item1.authors.first.name).to eq '福島地方気象台'
      expect(item1.authors.first.email).to be_nil
      expect(item1.authors.first.uri).to be_nil
      expect(item1.event_id).to eq '20160318182200_984'
      expect(item1.weather_xml).not_to be_nil
      expect(item1.weather_xml).to include('<InfoKind>気象警報・注意報</InfoKind>')
      expect(item1.state).to eq 'closed'

      item2 = model.site(site2).node(node2).where(rss_link: 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').first
      expect(item2.name).to eq item1.name
      expect(item2.rss_link).to eq item1.rss_link

      expect(Job::Log.count).to eq 5
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(SS::Task.count).to eq 3
      expect(SS::Task.where(site_id: nil).count).to eq 1
      expect(SS::Task.where(site_id: site1.id).count).to eq 1
      expect(SS::Task.where(site_id: site2.id).count).to eq 1
      SS::Task.where(site_id: nil).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml_all"
        expect(task.state).to eq "stop"
        expect(task.interrupt).to be_blank
        expect(task.started).to be_present
        expect(task.closed).to be_present
      end
      SS::Task.where(site_id: site1.id).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml"
        expect(task.state).to eq "stop"
      end
      SS::Task.where(site_id: site2.id).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml"
        expect(task.state).to eq "stop"
      end

      expect(@stab_seed1).to have_been_requested.times(1)
    end
  end

  context "retry: timeout and error" do
    before do
      @stab_seed1 = stub_request(:get, 'http://weather.example.jp/developer/xml/feed/other.xml').
        to_timeout.
        to_raise("some error").
        to_return(body: xml0, status: 200, headers: { 'Content-Type' => 'application/xml' })
      stub_request(:get, 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').
        to_return(status: [ 500, "Internal Server Error" ]).
        to_return(body: xml1, status: 200, headers: { 'Content-Type' => 'application/xml' })
      stub_request(:get, 'http://xml.kishou.go.jp/data/2b441518-4e79-342c-a271-7c25597f3a69.xml').
        to_return(status: [ 400, "Bad Request" ]).
        to_return(body: xml2, status: 200, headers: { 'Content-Type' => 'application/xml' })
    end

    it do
      expect { described_class.perform_now }.to change { model.count }.from(0).to(4)

      item1 = model.site(site1).node(node1).where(rss_link: 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').first
      expect(item1).not_to be_nil
      expect(item1.name).to eq '気象警報・注意報'
      expect(item1.rss_link).to eq 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml'
      expect(item1.html).to eq '【福島県気象警報・注意報】注意報を解除します。'
      expect(item1.released).to eq Time.zone.parse('2016-03-10T09:22:41Z')
      expect(item1.authors.count).to eq 1
      expect(item1.authors.first.name).to eq '福島地方気象台'
      expect(item1.authors.first.email).to be_nil
      expect(item1.authors.first.uri).to be_nil
      expect(item1.event_id).to eq '20160318182200_984'
      expect(item1.weather_xml).not_to be_nil
      expect(item1.weather_xml).to include('<InfoKind>気象警報・注意報</InfoKind>')
      expect(item1.state).to eq 'closed'

      item2 = model.site(site2).node(node2).where(rss_link: 'http://xml.kishou.go.jp/data/afeedc52-107a-3d1d-9196-b108234d6e0f.xml').first
      expect(item2.name).to eq item1.name
      expect(item2.rss_link).to eq item1.rss_link

      expect(Job::Log.count).to eq 5
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(SS::Task.count).to eq 3
      expect(SS::Task.where(site_id: nil).count).to eq 1
      expect(SS::Task.where(site_id: site1.id).count).to eq 1
      expect(SS::Task.where(site_id: site2.id).count).to eq 1
      SS::Task.where(site_id: nil).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml_all"
        expect(task.state).to eq "stop"
        expect(task.interrupt).to be_blank
        expect(task.started).to be_present
        expect(task.closed).to be_present
      end
      SS::Task.where(site_id: site1.id).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml"
        expect(task.state).to eq "stop"
      end
      SS::Task.where(site_id: site2.id).first.tap do |task|
        expect(task.name).to eq "rss:import_weather_xml"
        expect(task.state).to eq "stop"
      end

      expect(@stab_seed1).to have_been_requested.times(3)
    end
  end
end
