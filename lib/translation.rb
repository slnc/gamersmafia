# -*- encoding : utf-8 -*-
module Translation
  TRANSLATIONS = {
    'Advertiser' => 'Anunciante',
    'Bank' => 'Banco GM',
    'BazarManager' => 'Manager del bazar',
    'BulkUpload' => 'Subir contenidos en masa',
    'CompetitionAdmin' => 'Admin de competiciones',
    'CompetitionSupervisor' => 'Supervisor de competiciones',
    'ContentModerationQueue' => 'Cola de moderación',
    'DeleteContents' => 'Borrar contenidos',
    'EditContents' => 'Editar contenidos',
    'EditFaq' => 'Editar FAQ',
    'Gladiator' => 'Gladiador',
    'GmShop' => 'Tienda GM',
    'GroupAdministrator' => 'Administrador de grupo',
    'GroupMember' => 'Miembro de grupo',
    'ManoDerecha' => 'Mano derecha',
    'MassModerateContents' => 'Moderar contenidos en masa',
    'ProfileSignatures' => 'Dejar firmas',
    'RateCommentsDown' => 'Valorar comentarios negativamente',
    'RateCommentsUp' => 'Valorar comentarios positivamente',
    'RateContents' => 'Valorar contenidos',
    'ReportComments' => 'Reportar comentarios',
    'ReportContents' => 'Reportar contenidos',
    'ReportUsers' => 'Reportar usuarios',
    'TagContents' => 'Taguear contenidos',
  }

  def self.translate(word)
    translation = TRANSLATIONS[word]
    if translation.nil?
      Rails.logger.warn("Asked to translate '#{word}' but no translation found.")
    end
    translation || word
  end
end
