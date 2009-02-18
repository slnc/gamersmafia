class ClansLogsEntry < LogsEntry
  belongs_to :clan

  validates_presence_of :clan_id
end
