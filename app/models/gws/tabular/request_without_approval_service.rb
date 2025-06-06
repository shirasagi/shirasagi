class Gws::Tabular::RequestWithoutApprovalService < Gws::Workflow2::RequestWithoutApprovalService
  after_approve :release_item

  private

  def release_item
    return unless item.is_a?(SS::Release)

    now = Time.zone.now
    item.state = "public"
    item.released ||= now
    item.without_record_timestamps do
      item.save
    end
  end
end
