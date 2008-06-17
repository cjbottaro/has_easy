class HasEasyMigrationGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.migration_template "has_easy_migration.rb", "db/migrate"
    end
  end
end