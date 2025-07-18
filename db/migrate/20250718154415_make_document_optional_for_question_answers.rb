class MakeDocumentOptionalForQuestionAnswers < ActiveRecord::Migration[8.0]
  def change
    # Make document_id nullable
    change_column_null :question_answers, :document_id, true

    # Add index for query-based Q&As (without document)
    add_index :question_answers, [:organization_id, :document_id],
      where: "document_id IS NULL",
      name: "index_question_answers_on_org_id_where_no_doc"

    # Add source_type to track where the Q&A came from
    add_column :question_answers, :source_type, :string, default: "document"
    add_index :question_answers, :source_type
  end
end
