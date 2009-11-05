class CommentViolationOpinion < ActiveRecord::Base
    belongs_to :user
    belongs_to :comment

    VIOLATION = 0
    NO_VIOLATION = 1
    I_DONT_KNOW = 2

    validates_uniqueness_of :user_id, :scope => [ :comment_id ]
end
