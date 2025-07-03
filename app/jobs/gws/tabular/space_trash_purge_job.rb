class Gws::Tabular::SpaceTrashPurgeJob < Gws::ApplicationJob
  include Gws::TrashPurge::BaseJob

  self.model = Gws::Tabular::Space

  def perform(*_)
    count = 0

    all_ids = @items.pluck(:id)
    all_ids.each_slice(100) do |ids|
      @items.in(id: ids).to_a.each do |space|
        service = Gws::Tabular::Space::DeleteService.new(site: site, space: space)
        if service.call
          count += 1
        end
      end
    end

    message = "#{I18n.l(@threshold.to_date)}以前の#{model.model_name.human}を#{count}件削除しました。"
    Rails.logger.info message
    puts_history(:info, message)
  end
end
