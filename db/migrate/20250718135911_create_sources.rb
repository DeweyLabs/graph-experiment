class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :adapter_type
      t.json :config
      t.string :status
      t.datetime :last_sync_at
      t.json :sync_state

      t.timestamps
    end
  end
end
