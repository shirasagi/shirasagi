# Require `belongs_to` associations by default. Previous versions had false.
Mongoid::Config.belongs_to_required_by_default = false

# If you have met an error like "Attempted to instantiate an object of the unknown model 'Cms::Column::Value::SpotNotice'.",
# uncomment below lines and modify to fix an error
#
# Cms::Column::Base.add_discriminator_mapping("Cms::Column::SpotNotice")
# Cms::Column::Base.add_discriminator_mapping("Cms::Column::SpotMap")
# Cms::Column::Value::Base.add_discriminator_mapping("Cms::Column::Value::SpotNotice")
# Cms::Column::Value::Base.add_discriminator_mapping("Cms::Column::Value::SpotMap")
