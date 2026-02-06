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

    context "with SS::NotFoundError and custom message" do
      it do
        begin
          raise SS::NotFoundError, "not found"
        rescue => e
          expect(e).to be_a(SS::NotFoundError)
          expect(e.to_s).to eq "not found"
          expect(SS.not_found_error?(e)).to be_truthy
        end
      end
    end

    context "with Mongoid::Errors::DocumentNotFound" do
      it do
        begin
          Cms::Site.find(9_876_543_210)
        rescue => e
          expect(e).to be_a(Mongoid::Errors::DocumentNotFound)
          expect(SS.not_found_error?(e)).to be_truthy
        end
      end
    end
  end
end
