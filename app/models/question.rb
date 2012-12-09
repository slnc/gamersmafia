# -*- encoding : utf-8 -*-
class Unpublished < Exception; end
class AlreadyAnswered < Exception; end

# ContentAttribute:
# - ammount (numeric(10, 2))
# - answered_on (timestamp)
# - answer_selected_by_user_id (int)
class Question < Content
  MIN_AMMOUNT = 6.0
  DEFAULT_AMMOUNT = 5.0
  WARNING_AFTER_OPEN_FOR = 86400 * 7

  acts_as_categorizable

  has_one :last_updated_item, :class_name => 'Question'
  before_create :check_ammount
  before_create :check_max_open
  before_save :check_state
  before_save :check_switching_from_published

  has_bank_ammount_from_user

  validates_presence_of :title,
                        :message => 'El campo pregunta no puede estar en blanco'
  validates_length_of :title, :maximum => 100

  belongs_to :answer_selected_by_user,
             :foreign_key => :answer_selected_by_user_id, :class_name => 'User'

  scope :unanswered, :conditions => 'answered_on IS NULL'
  scope :answered, :conditions => 'answered_on IS NOT NULL'

  def self.close_old_open_questions
    mrman = Ias.MrMan
    Question.published.find(
        :all,
        :conditions => 'answered_on IS NULL AND created_on <= now() - \'1 month\'::interval',
        :order => 'id').each do |q|
      c_text = Kernel.rand > 0.5 ? 'Esta pregunta lleva pendiente de respuesta demasiado tiempo y le está empezando a salir musgo verde así que me veo en la obligación de cerrarla.' : 'Esta pregunta lleva demasiado tiempo abierta y se encuentra en paupérrimas condiciones. Por consiguiente me siento con la obligación de cerrarla.'

      if q.comments.count(:conditions => ['user_id <> ?', q.user_id]) > 0
        c_text << ' Si alguna de las respuestas es válida por favor avisad al staff.'
      end

      c = Comment.create(:user_id => mrman.id, :comment => c_text, :host => '127.0.0.1', :content_id => q.id)

      q.set_no_best_answer(mrman)
    end
  end


  def user_can_set_no_question?(user)
    # que pueda editar el contenido sin ser el autor o siendo el autor pero
    # siendo del hq
    (Authorization.can_edit_content?(user, self) && user.id != self.user_id)
  end

  def check_max_open
    if Question.published.count(
        :conditions => ['answered_on is NULL AND user_id = ?', self.user_id]) >= Question.max_open(self.user)
      self.errors[:base] << ('Tienes demasiadas preguntas abiertas. Debes esperar a que reciban respuesta o cancelarlas.')
      false
    else
      true
    end
  end

  def prize
   (self.ammount.nil? || self.ammount == 0.0) ? DEFAULT_AMMOUNT : self.ammount
  end

  def check_ammount
    if self.ammount.nil? || self.ammount == 0.0 || self.ammount >= MIN_AMMOUNT
      true
    else
      self.errors.add("ammount",
                      "Recompensa incorrecta. Debes o especificar una" +
                      " cantidad mayor que #{Question::MIN_AMMOUNT} o no" +
                      " especificar ninguna cantidad.")
      false
    end
  end

  def revert_set_best_answer(modifying_user)
    if self.state == Cms::PUBLISHED && self.answered_on
      t = CashMovement.find(:first, :conditions => ['description = ?', "Recompensa por mejor respuesta a la pregunta \"#{self.title}\""])

      if t or self.accepted_answer_comment_id.nil?
        Bank.revert_transfer(t) if t
        self.log_action('unset_respuesta', modifying_user.login)
        self.accepted_answer_comment_id = nil
        self.answer_selected_by_user_id = nil
        self.answered_on = nil
        if self.save
	true
	else
		false
	end
      else
        self.errors[:base] << ("No se puede revertir. No se ha encontrado la transferencia correspondiente.")
	false
      end
    end
  end

  def set_no_best_answer(modifying_user)
    self.answered_on = Time.now
    self.answer_selected_by_user_id = modifying_user.id
    if self.save
      self.log_action('set_sin_respuesta', modifying_user.login)
      if self.ammount
        Bank.transfer(
            :bank, self.user, self.prize,
            "Devolución por pregunta sin respuesta a \"#{self.title}\"")
      end
      true
    else
      false
    end
  end

  def set_best_answer(comment_id, modifying_user)
    if !self.comments_ids.include?(comment_id.to_s)
      self.errors[:base] << (
          'La respuesta especificada no se corresponde con esta pregunta.')
      false
    elsif self.answered_on
      self.errors[:base] << ('Esta pregunta ya tiene una mejor respuesta.')
      false
    else
      self.accepted_answer_comment_id = comment_id
      self.answered_on = Time.now
      self.answer_selected_by_user_id = modifying_user.id
      if self.save
        comment = Comment.find(comment_id)
        self.log_action('set_respuesta', modifying_user.login)
        if self.prize
          Bank.transfer(
              :bank,
              comment.user,
              self.prize,
              "Recompensa por mejor respuesta a la pregunta \"#{self.title}\"")
        end
        self.notify_observers(:after_question_answered)
        true
      else
        false
      end
    end
  end

  def best_answer
    if self.accepted_answer_comment_id.nil?
      nil
    else
      Comment.find(self.accepted_answer_comment_id)
    end
  end

  # TODO dup de topic.rb
  def check_state
    self.state = Cms::PUBLISHED if self.state < Cms::PUBLISHED
  end

  def update_avg_popularity
    # TODO tb limpiamos cache de avg_popularity de foro, pero aquí es mal lugar
    # TODO duplicado
    c = self.main_category
    c.avg_popularity = nil
    raise Exception unless c.save
  end

  def ammount_increase_message
    "Aumentas la recompensa por una buena respuesta para <strong>#{self.title}</strong>"
  end

  def ammount_decrease_message
    raise Exception("Imposible bajar el precio")
  end

  def ammount_returned
    "Devolución de la recompensa por la pregunta <strong>#{self.title}</strong>"
  end

  def ammount_owner
    self.user
  end

  def ammount_increase_checks(diff, new_ammount)
    raise AlreadyAnswered if self.answered_on
    raise Unpublished if self.state != Cms::PUBLISHED
    raise TooLateToLower if diff < 0 || (diff > 0 && new_ammount < Question::MIN_AMMOUNT)
  end

  def check_switching_from_published
    if (self.ammount && self.state_changed? &&
        self.state_was == Cms::PUBLISHED &&
        self.ammount > 0)
      return_to_owner
    end
    true
  end

  def self.max_open(user)
    if (user.created_on.to_i > Time.now.to_i - 1.week.ago.to_i ||
        user.karma_points == 0)
      # usuario es reciente
      5
    else
      10
    end
  end

  def self.top_sages(category=nil, limit=10)
    res = []
    # TODO(slnc): simplicar las queries SQL haciendo 2, una para obtener el top
    # y otra para cargar los usuarios.
    if category.nil?
      User.db_query("SELECT count(*) as points,
                          a.id,
                          a.avatar_id,
                          a.login,
                          a.cache_karma_points
                     FROM users a
                     join comments b on a.id = b.user_id
                    WHERE b.id IN (SELECT accepted_answer_comment_id
                                     FROM questions A
                                    WHERE state = #{Cms::PUBLISHED}
                                      AND accepted_answer_comment_id IS NOT NULL)
                 GROUP BY a.id,
                          a.login,
                          a.avatar_id,
                          a.cache_karma_points
		HAVING count(*) > 1
                 ORDER BY count(*) DESC,
                          lower(a.login)
                    LIMIT #{limit}").each do |dbu|
        res<< {:user => User.new(dbu.block_sym(:points)), :points => dbu['points'].to_i}
      end
    else
      term_ids = category.root.id
      self.top_term_sages(term_ids, 10)
    end
    res
  end

  def self.top_term_sages(term_ids, limit)
    term_ids = [term_ids] if term_ids.class == Fixnum
    res = []
    User.db_query(
        "SELECT count(a.id) as answers,
           a.id as user_id
         FROM users a
         JOIN comments b on a.id = b.user_id
         WHERE b.id IN (
           SELECT accepted_answer_comment_id
           FROM questions a
           JOIN contents b on a.id = b.id
           JOIN contents_terms c on b.id = c.content_id
           WHERE a.state = #{Cms::PUBLISHED}
           AND a.accepted_answer_comment_id IS NOT NULL
           AND c.term_id IN (#{term_ids.join(',')}))
         GROUP BY a.id,
           a.login,
           a.avatar_id,
           a.cache_karma_points
         ORDER BY count(a.id) DESC,
           LOWER(a.login)
         LIMIT #{limit}").each do |dbu|
      res<< {
        :user => User.find(dbu['user_id'].to_i),
        :points => dbu['answers'].to_i,
      }
    end
    res
  end

  def self.top_sages_in_date_range(date_start, date_end, limit=10)
    date_start, date_end = date_end, date_start if date_start > date_end

    User.db_query("SELECT count(*) as points, a.id, a.login
                     FROM users a JOIN comments b on a.id = b.user_id
                    WHERE b.id IN (SELECT accepted_answer_comment_id
                                     FROM questions
                                    WHERE state = #{Cms::PUBLISHED}
                                      AND answered_on BETWEEN '#{date_start.strftime('%Y-%m-%d %H:%M:%S')}'  AND '#{date_end.strftime('%Y-%m-%d %H:%M:%S')}'
                                      AND accepted_answer_comment_id IS NOT NULL)
                                 GROUP BY a.id, a.login
                                 ORDER BY count(*) DESC, lower(a.login) LIMIT #{limit}").collect do |dbu|
      [User.find(dbu['id']), dbu['points'].to_i]
    end
  end
end
