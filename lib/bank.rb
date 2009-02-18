class InsufficientCash < Exception; end
class TooLateToLower < Exception; end

module Bank
  class NegativeAmmountError < Exception; end
  class TransferDescriptionError < Exception; end
  class IdenticalEntityError < Exception; end
  
  def self.convert(ammount, units)
    raise NegativeAmmountError unless ammount >= 0
    # convierte una cantidad ammount de tipo units a su equivalente en gmd
    case units
      when 'karma_points':
      ammount * 0.2
      
      when 'faith_level':
      case ammount
        when 0:
        0
        when 1:
        5
        when 2:
        15
        when 3:
        35
        when 4:
        75
        when 5:
        100
      end
    end
  end
  
  # Ejecuta una transferencia entre dos entidades que implementen
  # has_bank_account. src o dst pueden ser :bank en cuyo caso el dinero nacerá
  # o desaparecerá en un agujero negro.
  #
  # Si el server se reinicia en cualquier momento puede quedar la
  # transferencia a medias y bien no recibir el destinatario el dinero o bien
  # no guardarse el log
  def self.transfer(src, dst, ammount, description)
    # puts "#{src}, #{dst}, #{ammount}, #{description}"
    raise NegativeAmmountError unless ammount > 0
    raise IdenticalEntityError if (src.class.name == dst.class.name && src.id == dst.id)
    description = description.to_s.strip
    raise TransferDescriptionError unless description != ''
    
    money_from_sender = src.remove_money(ammount) unless src == :bank
    dst.add_money(ammount) unless dst == :bank
    
    log_entry = CashMovement.new({:ammount => ammount, :description => description})
    
    if src != :bank
      log_entry.object_id_from = src.id
      log_entry.object_id_from_class = src.class.name
    end
    
    if dst != :bank
      log_entry.object_id_to = dst.id
      log_entry.object_id_to_class = dst.class.name
    end
    
    log_entry if log_entry.save
  end
  
  def self.cash(obj)
    CashMovement.db_query("select COALESCE((select sum(ammount) from cash_movements where object_id_to = #{obj.id} and object_id_to_class = '#{obj.class.name}'), 0) - COALESCE((select sum(ammount) from cash_movements where object_id_from = #{obj.id} and object_id_from_class = '#{obj.class.name}'), 0) as balance")[0]['balance'].to_f
  end
  
  def self.revert_transfer(cash_movement)
    cash_movement = CashMovement.find(cash_movement) unless cash_movement.kind_of?(CashMovement)
    
    if cash_movement.object_id_from then
      from = Object.const_get(cash_movement.object_id_from_class).find_by_id(cash_movement.object_id_from)
      from.add_money(cash_movement.ammount) if from
    end
    
    if cash_movement.object_id_to then
      to = Object.const_get(cash_movement.object_id_to_class).find_by_id(cash_movement.object_id_to)
      to.remove_money(cash_movement.ammount) if to
    end
    
    cash_movement.destroy
  end
  
  module Has
    
    # metodos a implementar por la clase:
    # ammount_owner por defecto
    # ammount_increase_message
    # ammount_decrease_message
    # ammount_returned
    # ammount_increase_checks(diff, new_ammount) opcional
    module BankAmmountFromUser
      def self.included(base)
        base.extend AddHasMethod
      end
      
      module AddHasMethod
        def has_bank_ammount_from_user
          class_eval <<-END
            include Bank::Has::BankAmmountFromUser::InstanceMethods
            # before_create :check_ammount_before_create
            after_create :update_ammount
            after_destroy :return_to_owner
          END
        end
      end
      
      
      module InstanceMethods        
        def update_ammount(new_ammount=nil)
          if new_ammount.nil? then
            new_ammount = self.ammount
            self.ammount = 0.0
            new_ammount = 0.0 if new_ammount.nil?
          end
          
          self.ammount = 0.0 if self.ammount.nil?
          u = self.ammount_owner
          new_ammount = new_ammount.to_f if (new_ammount.kind_of?(Fixnum) || new_ammount.kind_of?(BigDecimal))
          raise TypeError.new("#{new_ammount} #{new_ammount.class.name}") unless new_ammount.kind_of?(Float) && new_ammount >= 0
          diff = new_ammount - self.ammount
          
          raise InsufficientCash unless u.cash >= diff # TODO si es al crear tendremos que cambiar esto
          ammount_increase_checks(diff, new_ammount) if self.respond_to?(:ammount_increase_checks)
          
          if diff > 0 then # el user apuesta más que antes; salida de dinero de la cuenta del user
            Bank.transfer(u,
                          :bank,
                          diff,
                          self.ammount_increase_message)
          elsif diff < 0 # el user apuesta menos que antes, entrada de dinero
            Bank.transfer(:bank,
                          u,
             (-1) * diff,
            self.ammount_decrease_message)
          end
          
          self.ammount = new_ammount
          if self.save
            if self.respond_to?(:after_ammount_update)
              self.after_ammount_update
            else
              true
            end
          else
            false
          end
        end
        
        def return_to_owner
          if self.ammount > 0
            Bank.transfer(:bank, self.ammount_owner, self.ammount, self.ammount_returned)
            if !self.frozen?
              self.ammount = 0
              self.save
            end
            true
          end
        end  
      end
    end
    
    # Este módulo proporciona los métodos necesarios para que una clase pueda
    # enviar y recibir dinero. Una clase a la que se le quiera dotar con este
    # comportamiento debe tener una columna cash de tipo numeric(14,2).
    #
    # El atributo cash no se puede modificar a través de update o
    # update_attributes o para intentar garantizar atomicidad en las operaciones.
    module BankAccount
      def self.included(base)
        base.extend AddHasMethod
      end
      
      module AddHasMethod
        def has_bank_account
          attr_protected :cash
          
          class_eval <<-END
            include Bank::Has::BankAccount::InstanceMethods
          END
        end
      end
      
      # NO USAR remove_money y add_money directamente, usar Bank.transfer!
      module InstanceMethods
        public
        def remove_money(ammount)
          move_money(ammount, 'substract')
        end
        
        def add_money(ammount)
          move_money(ammount, 'add')
        end
        
        def cash=(val)
          raise 'cash= is prohibited'
        end
        
        
        private
        def move_money(ammount, opmode)
          sign = (opmode == 'add') ? '+' : '-'
          raise Bank::NegativeAmmountError unless ammount >= 0
          
          # Nos aseguramos de que modificamos siempre la cantidad que haya
          # actualizada en la bd por si el modelo ha recibido modificaciones
          # entre su carga y esta llamada
          @attributes['cash'] = db_query("UPDATE #{self.class.table_name} 
                                                 SET cash = cash #{sign} #{ammount} 
                                               WHERE id = #{self.id}; 

                                              SELECT cash 
                                                FROM #{self.class.table_name} 
                                               WHERE id = #{self.id};")[0]['cash']
        end
      end # module InstanceMethods
    end # module BankAccount
  end # module Has
end

ActiveRecord::Base.send(:include, Bank::Has::BankAccount)
ActiveRecord::Base.send(:include, Bank::Has::BankAmmountFromUser)