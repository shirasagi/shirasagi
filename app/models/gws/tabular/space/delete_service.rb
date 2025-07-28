class Gws::Tabular::Space::DeleteService
  include ActiveModel::Model

  attr_accessor :site, :space

  def call
    forms = Gws::Tabular::Form.unscoped.where(site_id: site.id, space_id: space.id)
    form_ids = forms.pluck(:id)

    return false unless space.destroy

    form_ids.each_slice(100) do |ids|
      forms.in(id: ids).to_a.each do |form|
        service = Gws::Tabular::Form::DeleteService.new(site: site, form: form)
        service.call
      end
    end

    true
  end
end
