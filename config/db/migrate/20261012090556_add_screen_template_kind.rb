# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :screen_template do
      add_column :mode, String, null: false, default: "text"
    end
  end
end
