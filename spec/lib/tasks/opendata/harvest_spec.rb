require 'spec_helper'

describe Tasks::Opendata::Harvest, dbscope: :example do
  describe ".each_sites" do
    let!(:site) { cms_site }
    let!(:node) { create :opendata_node_dataset, name: "opendata_dataset" }

    let!(:exporter1) { create :opendata_harvest_exporter, cur_node: node, state: "disabled" }
    let!(:exporter2) { create :opendata_harvest_exporter, cur_node: node, state: "disabled" }
    let!(:exporter3) { create :opendata_harvest_exporter, cur_node: node, state: "disabled" }

    let!(:importer1) { create :opendata_harvest_importer, cur_node: node, state: "disabled" }
    let!(:importer2) { create :opendata_harvest_importer, cur_node: node, state: "disabled" }
    let!(:importer3) { create :opendata_harvest_importer, cur_node: node, state: "disabled" }

    before do
      @save = {}
      ENV.each do |key, value|
        @save[key.dup] = value.dup
      end
    end

    after do
      ENV.clear
      @save.each do |key, value|
        ENV[key] = value
      end
    end

    context "run" do
      context "without params" do
        before { ENV['site'] = site.host }

        it do
          expectation = expect { described_class.run }
          expectation.to output(include(exporter1.url)).to_stdout
          expectation.to output(include(exporter2.url)).to_stdout
          expectation.to output(include(exporter3.url)).to_stdout
          expectation.to output(include(importer1.source_url)).to_stdout
          expectation.to output(include(importer2.source_url)).to_stdout
          expectation.to output(include(importer3.source_url)).to_stdout
        end
      end

      context "with exporter1" do
        before do
          ENV['site'] = site.host
          ENV['exporter'] = exporter1.id.to_s
        end

        it do
          expectation = expect { described_class.run }
          expectation.to output(include(exporter1.url)).to_stdout
          expectation.not_to output(include(exporter2.url)).to_stdout
          expectation.not_to output(include(exporter3.url)).to_stdout
          expectation.to output(include(importer1.source_url)).to_stdout
          expectation.to output(include(importer2.source_url)).to_stdout
          expectation.to output(include(importer3.source_url)).to_stdout
        end
      end

      context "with importer1" do
        before do
          ENV['site'] = site.host
          ENV['importer'] = importer1.id.to_s
        end

        it do
          expectation = expect { described_class.run }
          expectation.to output(include(exporter1.url)).to_stdout
          expectation.to output(include(exporter2.url)).to_stdout
          expectation.to output(include(exporter3.url)).to_stdout
          expectation.to output(include(importer1.source_url)).to_stdout
          expectation.not_to output(include(importer2.source_url)).to_stdout
          expectation.not_to output(include(importer3.source_url)).to_stdout
        end
      end

      context "with exporter1,exporter2,importer1" do
        before do
          ENV['site'] = site.host
          ENV['exporters'] = "#{exporter1.id},#{exporter2.id}"
          ENV['importers'] = importer1.id.to_s
        end

        it do
          expectation = expect { described_class.run }
          expectation.to output(include(exporter1.url)).to_stdout
          expectation.to output(include(exporter2.url)).to_stdout
          expectation.not_to output(include(exporter3.url)).to_stdout
          expectation.to output(include(importer1.source_url)).to_stdout
          expectation.not_to output(include(importer2.source_url)).to_stdout
          expectation.not_to output(include(importer3.source_url)).to_stdout
        end
      end

      context "with invalid params" do
        before do
          ENV['site'] = site.host
          ENV['exporters'] = "9999"
          ENV['importers'] = "9999"
        end
        it do
          expectation = expect { described_class.run }
          expectation.not_to output(include(exporter1.url)).to_stdout
          expectation.not_to output(include(exporter2.url)).to_stdout
          expectation.not_to output(include(exporter3.url)).to_stdout
          expectation.not_to output(include(importer1.source_url)).to_stdout
          expectation.not_to output(include(importer2.source_url)).to_stdout
          expectation.not_to output(include(importer3.source_url)).to_stdout
        end
      end
    end

    context "export" do
      context "with exporter1" do
        before do
          ENV['site'] = site.host
          ENV['exporter'] = exporter1.id.to_s
        end

        it do
          expectation = expect { described_class.export }
          expectation.to output(include(exporter1.url)).to_stdout
          expectation.not_to output(include(exporter2.url)).to_stdout
          expectation.not_to output(include(exporter3.url)).to_stdout
          expectation.not_to output(include(importer1.source_url)).to_stdout
          expectation.not_to output(include(importer2.source_url)).to_stdout
          expectation.not_to output(include(importer3.source_url)).to_stdout
        end
      end

      context "with exporter1,exporter2" do
        before do
          ENV['site'] = site.host
          ENV['exporters'] = "#{exporter1.id},#{exporter2.id}"
        end

        it do
          expectation = expect { described_class.export }
          expectation.to output(include(exporter1.url)).to_stdout
          expectation.to output(include(exporter2.url)).to_stdout
          expectation.not_to output(include(exporter3.url)).to_stdout
          expectation.not_to output(include(importer1.source_url)).to_stdout
          expectation.not_to output(include(importer2.source_url)).to_stdout
          expectation.not_to output(include(importer3.source_url)).to_stdout
        end
      end
    end

    context "import" do
      context "with importer1" do
        before do
          ENV['site'] = site.host
          ENV['importer'] = importer1.id.to_s
        end

        it do
          expectation = expect { described_class.import }
          expectation.not_to output(include(exporter1.url)).to_stdout
          expectation.not_to output(include(exporter2.url)).to_stdout
          expectation.not_to output(include(exporter3.url)).to_stdout
          expectation.to output(include(importer1.source_url)).to_stdout
          expectation.not_to output(include(importer2.source_url)).to_stdout
          expectation.not_to output(include(importer3.source_url)).to_stdout
        end
      end

      context "with importer1,importer2" do
        before do
          ENV['site'] = site.host
          ENV['importers'] = "#{importer1.id},#{importer2.id}"
        end

        it do
          expectation = expect { described_class.import }
          expectation.not_to output(include(exporter1.url)).to_stdout
          expectation.not_to output(include(exporter2.url)).to_stdout
          expectation.not_to output(include(exporter3.url)).to_stdout
          expectation.to output(include(importer1.source_url)).to_stdout
          expectation.to output(include(importer2.source_url)).to_stdout
          expectation.not_to output(include(importer3.source_url)).to_stdout
        end
      end
    end
  end
end
