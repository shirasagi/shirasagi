require 'spec_helper'

describe SS::MaxFileSize, type: :model, dbscope: :example do
  describe ".nginx_client_max_body_size" do
    context "when nginx is deployed" do
      it do
        expect(SS::MaxFileSize.nginx_client_max_body_size).to be_present
      end
    end

    context "when apache httpd is deployed" do
      let(:stub_class) do
        Class.new do
          def spawn(*_args)
            raise Errno::ENOENT, "nginx"
          end
        end
      end

      it do
        mod = stub_class.new
        expect(SS::MaxFileSize.nginx_client_max_body_size(mod: mod)).to be_present
      end
    end
  end

  describe ".load_nginx_client_max_body_size" do
    let(:file_path) do
      tmpfile do |file|
        file.puts "#client_max_body_size 100m;"
        file.puts "client_max_body_size 300m;"
        file.puts "client_body_buffer_size 256k;"
      end
    end

    it do
      size = ::File.open(file_path, "r") do |file|
        SS::MaxFileSize.send(:load_nginx_client_max_body_size, file)
      end

      expect(size).to eq 300 * 1024 * 1024
    end
  end
end
