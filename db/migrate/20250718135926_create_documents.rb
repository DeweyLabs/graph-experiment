class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :source, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :external_id
      t.string :title
      t.text :content
      t.json :metadata
      t.string :embedding_status
      t.integer :chunk_count
      t.datetime :processed_at

      t.timestamps
    end
  end
end
