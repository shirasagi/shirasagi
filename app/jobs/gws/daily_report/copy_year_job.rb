class Gws::DailyReport::CopyYearJob < Gws::ApplicationJob
  def perform(src_year, dest_year)
    model = Gws::DailyReport::Form
    forms = model.site(site).without_deleted.where(year: src_year)
    forms.each do |form|
      attributes = form.dup.attributes
      attributes.delete(:_id)
      new_form = model.new(form.dup.attributes)
      new_form.cur_site = site
      new_form.cur_user = user
      new_form.name = form.name.gsub(src_year, dest_year)
      new_form.year = dest_year
      new_form.memo = form.memo.gsub(src_year, dest_year)
      new_form.save!
      form.columns.each do |column|
        col_class = column[:_type].constantize
        col = col_class.site(site).form(new_form).where(name: column.name).first || col_class.new

        attributes = column.dup.attributes
        attributes.delete(:_id)
        col.attributes = attributes
        col.cur_site = site
        col.form_id = new_form.id
        col.save! if col.changed?
      end

      Rails.logger.info("#{new_form.name}: Create work category.")
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      false
    end
  end
end
