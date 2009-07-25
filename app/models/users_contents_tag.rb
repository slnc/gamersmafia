class UsersContentsTag < ActiveRecord::Base
  belongs_to :user
  belongs_to :term
  belongs_to :content
  
  before_create :resolve_term
  validates_format_of :original_name, :with => /^[a-z0-9.]{1,30}$/i, :message => 'El tag tiene más de 30 caracteres o bien contiene caracteres ilegales (solo se permiten letras, numeros y puntos)'
  validates_uniqueness_of :term_id, :scope => [:content_id, :user_id]
  
  private
  def resolve_term
    t = Term.contents_tags.find_by_name(self.original_name.downcase)
    if t.nil?
      t = Term.create(:taxonomy => 'ContentsTag', :name => self.original_name.downcase)
    end
    self.term_id = t.id
    
    # El validates_uniqueness_of de arriba no está funcionando
    UsersContentsTag.count(:conditions => ['term_id = ? AND user_id = ? AND content_id = ?', self.term_id, self.user_id, self.content_id]) == 0
  end
  
  public
  def self.tag_content(content, user, tag_str)
    return if tag_str.length > 300 or tag_str.count(' ') > 7
    tags_to_delete = content.users_contents_tags.find(:all, :conditions => ['user_id = ?', user.id])
    tags_to_delete ||= []
    tag_str.split(' ').each do |tag|
      uct = UsersContentsTag.create(:user_id => user.id, :content_id => content.id, :original_name => tag)
      tags_to_delete = tags_to_delete.delete_if { |item| item.original_name == uct.original_name }
    end
    tags_to_delete.each do |item| item.destroy end
    
    # TODO recalcular terms reales
  end
end
