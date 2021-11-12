DECLARE
  @DATESTART DATE,
  @DISTRIBUTEBYDAYS INT,
  @DAYS INT,
  @PROTCOUNT INT,
  @STARTPOSITION INT,
  @STOPPOSITION INT

  EXEC spDrop '#ProtocolIDs'

  SET @DATESTART = GETDATE()
  SET @DISTRIBUTEBYDAYS = 7

  SELECT 
    ID = ROW_NUMBER() OVER (ORDER BY Created),
    ProtocolID = ID,
    [Distributed] = 0,
    [Day] = 0,
    Created
  INTO #ProtocolIDs
  FROM pm.Protocol (NOLOCK)
  WHERE CAST(Created AS DATE) = @DATESTART

  SELECT 
    --@PROTCOUNT = COUNT(*) / @DISTRIBUTEBYDAYS 
    @PROTCOUNT = CASE 
      WHEN COUNT(*) < 7 AND COUNT(*) > 0 THEN COUNT(*)
      ELSE COUNT(*) / @DISTRIBUTEBYDAYS 
    END
  FROM #ProtocolIDs
    
  --SELECT * FROM #ProtocolIDs
  --SELECT @PROTCOUNT

  SET @DAYS = 0
  SET @STARTPOSITION = 0
  SET @STOPPOSITION = 0

  WHILE @DISTRIBUTEBYDAYS > 0
  BEGIN
    SET @DAYS = @DAYS + 1

    SET @STOPPOSITION = @STOPPOSITION + @PROTCOUNT

    --SELECT @DAYS, @STARTPOSITION, @STOPPOSITION

    UPDATE #ProtocolIDs
    SET [Day] = @DAYS, [Distributed] = 1
    WHERE ID > @STARTPOSITION AND ID <= @STOPPOSITION AND [Distributed] = 0
  
    SET @STARTPOSITION = @STOPPOSITION
    
    --select * from #ProtocolIDs

    UPDATE pm.Protocol
    SET Created = DATEADD(DAY, -@DAYS, Created)
    WHERE ID IN (SELECT tmpp.ProtocolID FROM #ProtocolIDs tmpp WHERE tmpp.[Distributed] = 1 AND tmpp.[Day] = @DAYS) 
   
    UPDATE lx.Inquiry
    SET 
      Received = DATEADD(DAY, -@DAYS - 1, Received),
      [Sent] = DATEADD(DAY, -@DAYS - 1, [Sent])
    WHERE 
      ID IN (
        SELECT InquiryID FROM pm.ProtocolNode WITH(NOLOCK, NOEXPAND) WHERE ProtocolID IN (
          SELECT tmpp.ProtocolID FROM #ProtocolIDs tmpp 
          WHERE tmpp.[Distributed] = 1 AND tmpp.[Day] = @DAYS          
        ) 
        GROUP BY InquiryID
      )

    SET @DISTRIBUTEBYDAYS = @DISTRIBUTEBYDAYS - 1
  END

  SELECT * FROM pm.Protocol (NOLOCK)
  WHERE ID IN (SELECT ProtocolID FROM #ProtocolIDs)
  ORDER BY Created
  
  SELECT * FROM lx.Inquiry (NOLOCK)
  WHERE ID IN (
    SELECT InquiryID FROM pm.ProtocolNode WITH(NOLOCK, NOEXPAND) 
    WHERE ProtocolID IN (
      SELECT tmpp.ProtocolID FROM #ProtocolIDs tmpp
    )
  )
  ORDER BY Received

  SELECT * FROM #ProtocolIDs
  
