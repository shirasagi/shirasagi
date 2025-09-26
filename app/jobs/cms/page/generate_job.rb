class Cms::Page::GenerateJob < Cms::ApplicationJob
  include Job::Cms::GeneratorFilter

  queue_as { segment.presence || :default }

  self.task_class = Cms::Task
  self.task_name = "cms:generate_pages"
  self.controller = Cms::Agents::Tasks::PagesController
  self.action = :generate

  def segment
    # Cms::Agents::Tasks::NodesController へ引き継がれないように、インスタンス変数の先頭に "_" をつける
    return @_segment if instance_variable_defined?(:@_segment)

    options = arguments.last.then { _1.is_a?(Hash) && _1.extractable_options? ? _1 : SS::EMPTY_HASH }
    seg = options[:segment] || options["segment"]

    if seg.blank?
      @_segment = nil
      return @_segment
    end

    all_segments = site.generate_page_segments
    unless all_segments.include?(seg)
      @_segment = nil
      return @_segment
    end

    @_segment = seg
  end

  def task_cond
    cond = super
    cond[:segment] = segment
    cond
  end
end
