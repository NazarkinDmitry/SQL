DECLARE
  @ObjName NVARCHAR(200),
  @Txt NVARCHAR(MAX)

EXEC spDrop '#HasPrepareDoc'
CREATE TABLE #HasPrepareDoc (ObjName NVARCHAR(200), ObjType  NVARCHAR(200), Txt  NVARCHAR(MAX))

INSERT INTO #HasPrepareDoc
EXEC spFindTextInSP 'sp_xml_preparedocument'

DECLARE crProcesses INSENSITIVE CURSOR FOR			
SELECT ObjName, Txt FROM #HasPrepareDoc

OPEN crProcesses
WHILE 1=1
BEGIN
	FETCH NEXT FROM crProcesses INTO @ObjName, @Txt
	IF @@FETCH_STATUS <> 0 BREAK
  IF CHARINDEX('sp_xml_removedocument', @Txt, 1) = 0
    SELECT @ObjName
END
DEALLOCATE crProcesses