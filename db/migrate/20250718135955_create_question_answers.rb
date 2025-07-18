class CreateQuestionAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :question_answers do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.text :question
      t.text :answer
      t.text :context
      t.float :confidence_score
      t.json :metadata
      t.string :pinecone_id

      t.timestamps
    end
  end
end
