class TQNerAnnotateComment < TrainingQuestion
  # _ner_annotate_main: plain text of a comment
  # _ner_annotate_main_annotated: newline separated list of entities, don't include repeated 
  #   ones
  # in: "hello Mr Anderson."
  # out: "Mr\nAnderson"
  
  after_save :create_named_entities_if_necessary
  
  validates_presence_of :_ner_annotate_comment_main
  validates_presence_of :_ner_annotate_comment_comment_id
  
  named_scope :answered, :conditions => ['_ner_annotate_comment_main_annotated IS NOT NULL']
  named_scope :unanswered, :conditions => ['_ner_annotate_comment_main_annotated IS NULL']
  belongs_to :comment, :foreign_key => :_ner_annotate_comment_comment_id
  
  observe_attr :_ner_annotate_comment_main_annotated
  
  # Updates the comment_main field with what the current simplify_text says.
  def self.update_comments_mains_with_current_simplify
    Comment.find_each do |comment|
      question = TQNerAnnotateComment.find_by__ner_annotate_comment_comment_id(comment.id)
      if question.nil?
        Rails.logger.warn("no question for #{comment.id} #{comment.created_on}")
        next
      end
      question.update_attribute(:_ner_annotate_comment_main, 
                                TextTools.simplify_text(comment.main))
    end
  end
  
  def annotated?
    !self._ner_annotate_comment_main_annotated.nil?
  end
  
  def create_named_entities_if_necessary(skip_check_only_if_changed=false)
    return unless self.annotated?
    
    if self.slnc_changed?(:_ner_annotate_comment_main_annotated) or skip_check_only_if_changed
      self._ner_annotate_comment_main_annotated.strip.split("\r").each do |w|
        w = w.strip
        ne = NamedEntity.find_by_name(w)
        ne = NamedEntity.create(:name => w) unless ne
        
        if ne.new_record?
          puts "first ne: #{ne} while searching for #{w}"
          puts "------ name: #{w}"
          puts "Error: model unsaved: #{ne.errors.full_messages_html} | #{ne.slug}"
        else
          ne.link_to_content_or_increase_weight(self.comment.content)
        end
      end
    end
  end
end
