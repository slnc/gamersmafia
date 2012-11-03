# -*- encoding : utf-8 -*-
module Translation
  TRANSLATIONS = {
    'Advertiser' => 'Anunciante',
    'Bank' => 'Banco GM',
    'BazarManager' => 'Manager del bazar',
    'Bet' => 'Apuesta',
    'Blogentry' => 'Entrada de blog',
    'BulkUpload' => 'Subir contenidos en masa',
    'Column' => 'Columna',
    'CompetitionAdmin' => 'Admin de competiciones',
    'CompetitionSupervisor' => 'Supervisor de competiciones',
    'ContentModerationQueue' => 'Cola de moderación',
    'DeleteContents' => 'Borrar contenidos',
    'Download' => 'Descarga',
    'EditContents' => 'Editar contenidos',
    'EditFaq' => 'Editar FAQ',
    'Event' => 'Evento',
    'Funthing' => 'Curiosidad',
    'Gladiator' => 'Gladiador',
    'GmShop' => 'Tienda GM',
    'GroupAdministrator' => 'Administrador de grupo',
    'GroupMember' => 'Miembro de grupo',
    'Image' => 'Imagen',
    'Interview' => 'Entrevista',
    'LessAds' => 'Menos publicidad',
    'ManoDerecha' => 'Mano derecha',
    'MassModerateContents' => 'Moderar contenidos en masa',
    'News' => 'Noticia',
    'Poll' => 'Encuesta',
    'ProfileSignatures' => 'Dejar firmas',
    'Question' => 'Pregunta',
    'RateCommentsDown' => 'Valorar comentarios negativamente',
    'RateCommentsUp' => 'Valorar comentarios positivamente',
    'RateContents' => 'Valorar contenidos',
    'RecruitmentAd' => 'Anuncio de reclutamiento',
    'ReportComments' => 'Reportar comentarios',
    'ReportContents' => 'Reportar contenidos',
    'ReportUsers' => 'Reportar usuarios',
    'TagContents' => 'Taguear contenidos',
  }

  def self.translate(word)
    TRANSLATIONS[word] || word
  end
end
