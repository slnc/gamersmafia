# -*- encoding : utf-8 -*-
namespace :gm do
  desc "GmGeist Warning 2011"
  task :gmgeist2011 => :environment do
    subject = '¡Sólo quedan 2 días para que concluya la GmGeist 2011!'
    body = '''Si todavía no has rellenado la primera encuesta anual de Gamersmafia esta es tu oportunidad:

    http://gamersmafia.com/noticias/show/45704

    Tu opinión es imprescindible para poder decidir el rumbo de la comunidad.
    ¡Muchas gracias!
    '''
    nagato = User.find_by_login('nagato')
    recipient = User.find(1)
    m = Message.new(:title => subject, :sender => nagato, :recipient => recipient, :message => body)
    m.save
  end
end
