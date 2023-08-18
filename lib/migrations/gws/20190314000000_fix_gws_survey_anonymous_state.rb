class SS::Migration20190314000000
  include SS::Migration::Base

  depends_on "20190306000000"

  def change
    each_form_and_file do |form, file|
      if file.anonymous_state.blank?
        file.anonymous_state = form.anonymous_state
        file.save!
      end
    end
  end

  private

  def each_form(&block)
    all_ids = Gws::Survey::Form.all.where(anonymous_state: "enabled").pluck(:id)
    all_ids.each_slice(20) do |ids|
      forms = Gws::Survey::Form.all.in(id: ids).to_a
      forms.each(&block)
    end
  end

  def each_file(form, &block)
    all_ids = Gws::Survey::File.all.where(form_id: form.id).pluck(:id)
    all_ids.each_slice(20) do |ids|
      files = Gws::Survey::File.all.in(id: ids).to_a
      files.each(&block)
    end
  end

  def each_form_and_file
    each_form do |form|
      each_file(form) do |file|
        yield form, file
      end
    end
  end
end
