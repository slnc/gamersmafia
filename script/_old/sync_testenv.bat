cd "C:\Documents and Settings\slnc\workspace\gamersmafia"
rake test:sync_from_development
del /Q "C:\Documents and Settings\slnc\workspace\gamersmafia\tmp\sessions\*"
rake log:clear