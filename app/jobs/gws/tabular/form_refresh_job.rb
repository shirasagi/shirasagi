#frozen_string_literal: true

class Gws::Tabular::FormRefreshJob < Gws::ApplicationJob
  def perform
    Rails.logger.tagged(site.name) do
      items.each do |item|
        Rails.logger.tagged(item.name) do
          current_release = item.current_release
          next unless current_release

          generator = Gws::Tabular::File::Generator.new(form_release: current_release)
          Gws::Tabular::File.mutex.synchronize do
            # prepare
            if ::File.exist?(generator.target_file_path)
              save_mtime = ::File.mtime(generator.target_file_path)
              FileUtils.rm_f(generator.target_file_path)
            end

            # rewrite
            generator.call

            # finalize
            if save_mtime && ::File.exist?(generator.target_file_path)
              ::File.utime(Time.zone.now.to_time, save_mtime, generator.target_file_path)
            end

            # クラスの再読み込み
            Gws::Tabular.send(:remove_const, generator.model_name) if Gws::Tabular.const_defined?(generator.model_name)
            load generator.target_file_path
            Gws::Tabular.const_get(generator.model_name)
          end
        end
      end
    rescue => e
      Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      raise
    end
  end

  private

  def items
    @items ||= Gws::Tabular::Form.site(site).and_public.to_a
  end
end
