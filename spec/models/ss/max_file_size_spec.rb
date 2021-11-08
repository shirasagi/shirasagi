require 'spec_helper'

describe SS::MaxFileSize, type: :model, dbscope: :example do
  describe ".nginx_client_max_body_size" do
    it do
      expect(SS::MaxFileSize.nginx_client_max_body_size).to be_present
    end
  end
end
