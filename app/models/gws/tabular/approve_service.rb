class Gws::Tabular::ApproveService < Gws::Workflow2::ApproveService
  after_approve :release_item

  private

  def release_item
    return unless work_item.is_a?(SS::Release)

    now = Time.zone.now
    work_item.state = "public"
    work_item.released ||= now
    work_item.without_record_timestamps do
      work_item.save
    end
  end
end
