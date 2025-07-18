class CreateDocumentChunks < ActiveRecord::Migration[8.0]
  def change
    create_table :document_chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.text :content
      t.integer :chunk_index
      t.text :embedding
      t.string :pinecone_id
      t.json :metadata

      t.timestamps
    end
  end
end
