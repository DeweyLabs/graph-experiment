class SetupInitialSchema < ActiveGraph::Migrations::Base
  def up
    # Create constraints for unique global_id across all node types
    add_constraint :DocumentNode, :global_id, type: :unique
    add_constraint :EntityNode, :global_id, type: :unique
    add_constraint :QuestionNode, :global_id, type: :unique
    add_constraint :ClaimNode, :global_id, type: :unique
    add_constraint :EvidenceNode, :global_id, type: :unique
    add_constraint :TopicNode, :global_id, type: :unique

    # Create basic indexes for multi-tenancy
    add_index :DocumentNode, :organization_id
    add_index :EntityNode, :organization_id
    add_index :QuestionNode, :organization_id
    add_index :ClaimNode, :organization_id
    add_index :EvidenceNode, :organization_id
    add_index :TopicNode, :organization_id

    # Essential lookup indexes
    add_index :EntityNode, :normalized_name
    add_index :DocumentNode, :content_hash
  end

  def down
    # Remove indexes
    remove_index :DocumentNode, :content_hash
    remove_index :EntityNode, :normalized_name
    remove_index :TopicNode, :organization_id
    remove_index :EvidenceNode, :organization_id
    remove_index :ClaimNode, :organization_id
    remove_index :QuestionNode, :organization_id
    remove_index :EntityNode, :organization_id
    remove_index :DocumentNode, :organization_id

    # Remove constraints
    remove_constraint :TopicNode, :global_id
    remove_constraint :EvidenceNode, :global_id
    remove_constraint :ClaimNode, :global_id
    remove_constraint :QuestionNode, :global_id
    remove_constraint :EntityNode, :global_id
    remove_constraint :DocumentNode, :global_id
  end
end
