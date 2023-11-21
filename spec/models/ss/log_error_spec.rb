require 'spec_helper'

describe SS, type: :model, dbscope: :example do
  describe ".log_error" do
    let(:log_file) { tmpfile }
    let!(:logger) do
      logger = ::Logger.new(log_file, formatter: Logger::Formatter.new)
      ActiveSupport::TaggedLogging.new(logger)
    end

    context "single error" do
      it do
        begin
          raise "error"
        rescue => e
          error = e
        end

        SS.log_error(error, logger: logger)

        logs = ::File.readlines(log_file)
        expect(logs).to have_at_least(1).items
        expect(logs).to include(/ERROR -- : RuntimeError \(error\)/)
      end
    end

    context "hierarchical error with recursive false" do
      it do
        begin
          begin
            raise "inner error"
          rescue
            raise "outer error"
          end
        rescue => e
          error = e
        end

        SS.log_error(error, logger: logger, recursive: false)

        logs = ::File.readlines(log_file)
        expect(logs).to have_at_least(1).items
        expect(logs).to include(/ERROR -- : RuntimeError \(outer error\)/)
        expect(logs).not_to include(/inner error/)
      end
    end

    context "hierarchical error with recursive true" do
      it do
        begin
          begin
            raise "inner error"
          rescue
            raise "outer error"
          end
        rescue => e
          error = e
        end

        SS.log_error(error, logger: logger, recursive: true)

        logs = ::File.readlines(log_file)
        expect(logs).to have_at_least(1).items
        expect(logs).to include(/ERROR -- : RuntimeError \(outer error\)/)
        expect(logs).to include(/ERROR -- : \[outer error\] RuntimeError \(inner error\)/)
      end
    end
  end
end
