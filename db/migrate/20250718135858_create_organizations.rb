class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :subdomain
      t.json :settings
      t.string :plan
      t.string :status

      t.timestamps
    end
  end
end
