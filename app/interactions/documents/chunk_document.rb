module Documents
  class ChunkDocument < ApplicationInteraction
    object :document, class: Document
    integer :chunk_size, default: 1000
    integer :chunk_overlap, default: 200
    
    validates :chunk_size, numericality: { greater_than: 100, less_than: 5000 }
    validates :chunk_overlap, numericality: { greater_than_or_equal_to: 0, less_than: :chunk_size }
    
    def execute
      return unless document.ready_for_chunking?
      
      document.mark_processing!
      
      chunks = create_chunks
      
      if chunks.any?
        document.mark_completed!
        chunks
      else
        document.mark_failed!("No chunks created")
        errors.add(:base, "Failed to create chunks")
      end
    end
    
    private
    
    def create_chunks
      content = document.content
      chunks = []
      position = 0
      chunk_index = 0
      
      while position < content.length
        chunk_end = [position + chunk_size, content.length].min
        
        # Try to break at a sentence boundary
        if chunk_end < content.length
          last_period = content.rindex('.', chunk_end)
          last_newline = content.rindex("\n", chunk_end)
          
          break_point = [last_period, last_newline].compact.max
          chunk_end = break_point + 1 if break_point && break_point > position
        end
        
        chunk_content = content[position...chunk_end].strip
        
        if chunk_content.present?
          chunk = document.document_chunks.create!(
            organization: document.organization,
            content: chunk_content,
            chunk_index: chunk_index,
            metadata: {
              start_position: position,
              end_position: chunk_end,
              length: chunk_content.length
            }
          )
          chunks << chunk
          chunk_index += 1
        end
        
        position = chunk_end - chunk_overlap
        position = chunk_end if position <= 0
      end
      
      chunks
    rescue => e
      errors.add(:base, "Chunking error: #{e.message}")
      []
    end
  end
end