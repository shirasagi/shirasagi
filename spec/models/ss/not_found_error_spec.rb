require 'spec_helper'

describe SS, dbscope: :example do
  describe ".not_found_error?" do
    context "with '404'" do
      it do
        begin
          raise "404"
        rescue => e
          expect(e.to_s).to eq "404"
          expect(SS.not_found_error?(e)).to be_truthy
        end
      end
    end

    context "with SS::NotFoundError" do
      it do
        begin
          raise SS::NotFoundError
        rescue => e
          expect(e).to be_a(SS::NotFoundError)
          expect(e.to_s).to eq "404"
          expect(SS.not_found_error?(e)).to be_truthy
        end
      end
    end

    context "with Mongoid::Errors::DocumentNotFound" do
      it do
        begin
          SS::Site.find(9876543210)
        rescue => e
          expect(e).to be_a(Mongoid::Errors::DocumentNotFound)
          expect(SS.not_found_error?(e)).to be_truthy
        end
      end
    end
  end
end
