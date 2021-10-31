$databaseFolder = "${HOME}\OneDrive\デスクトップ\SQLite"

# System.Data.sqlite.dllのロード
$asm = [System.Reflection.Assembly]::LoadFile("${databaseFolder}\System.Data.sqlite.dll")

# SQLiteへの接続およびSQLステートメント発行用のSystem.Data.SQLite.SQLiteCommandの生成
$sqlite = New-Object System.Data.SQLite.SQLiteConnection

$sqlite.ConnectionString = "Data Source = ${databaseFolder}\manager.db; Version = 3; JournalMode = Wal;"
$sqlcmd = New-Object System.Data.SQLite.SQLiteCommand
$sqlcmd.Connection = $sqlite
$sqlite.Open()

# SQLiteCommandの破棄
# これをしないと、以下のSQL発行で以下の例外メッセージが表示され中断されます。
# "DataReader already active on this command"
#$sqlcmd.Dispose()
$sql = "CREATE TABLE IF NOT EXISTS ManagerTable (id INTEGER PRIMARY KEY AUTOINCREMENT, firstTime TEXT, firstData TEXT, lastTime TEXT, lastData TEXT);"
$sqlcmd.CommandText = $sql
$ret = $sqlcmd.ExecuteNonQuery()

# SQLiteの切断
$sqlcmd.Dispose()
$sqlite.Close()

#==========================================================-

# SQLiteへの接続およびSQLステートメント発行用のSystem.Data.SQLite.SQLiteCommandの生成
$sqlite = New-Object System.Data.SQLite.SQLiteConnection
$sqlite.ConnectionString = "Data Source = ${databaseFolder}\data.db; Version = 3; JournalMode = Wal;"
$sqlcmd = New-Object System.Data.SQLite.SQLiteCommand
$sqlcmd.Connection = $sqlite
$sqlite.Open()

# SQLiteCommandの破棄
# これをしないと、以下のSQL発行で以下の例外メッセージが表示され中断されます。
# "DataReader already active on this command"
#sqlcmd.Dispose()

# テーブルの作成
$sqlcmd = New-Object System.Data.SQLite.SQLiteCommand
$sqlcmd.Connection = $sqlite
$sql = "CREATE TABLE IF NOT EXISTS OpeHistoryTable (id INTEGER PRIMARY KEY AUTOINCREMENT, time TEXT, data TEXT);"
$sqlcmd.CommandText = $sql
$ret = $sqlcmd.ExecuteNonQuery()

# Indexの作成
$sql = "CREATE INDEX IF NOT EXISTS dateIdx ON OpeHistoryTable ( time );"
$sqlcmd.CommandText = $sql
$ret = $sqlcmd.ExecuteNonQuery()

# manager.dbとのATTACH
$sql = "ATTACH '${databaseFolder}\manager.db' AS shm"
$sqlcmd.CommandText = $sql
$ret = $sqlcmd.ExecuteNonQuery()

$dayCnt = 0

# INSERT実行
while ($dayCnt -lt 3) {

  # 日時のリセット
  $dateTime = [DateTime]::ParseExact("2019/01/01 00:00:00","yyyy/MM/dd HH:mm:ss", $null);
  $dateTime = $dateTime.AddDays( $dayCnt )

  # トランザクションの開始
  $transaction = $sqlite.BeginTransaction();

  for($j=0; $j -lt 10; $j++){
    # Manager.dbの設定項目
    $firstDateTime = $dateTime
    $firstData = "{0:D10}" -f 1
    $lastDateTime = ""
    $lastData = ""

    for($i=1; $i -le 10; $i++){
      $id = $i;
      $no = $j * 1000 + $i
      $data = "{0:D10}" -f $no
      $dateTimeText = ${dateTime}.ToString("yyyy/MM/dd HH:mm:ss")
  
      $sql="INSERT INTO OpeHistoryTable ( time, data ) VALUES( '${dateTimeText}', '${data}' )"
      $sqlcmd.CommandText = $sql
      $ret = $sqlcmd.ExecuteNonQuery()
  
      $lastDateTime = $dateTimeText
      $lastData = $data
  
      $dateTime = $dateTime.AddSeconds(1)
    }

    # Manager.dbに開始日時と終了日時の追加
    $sql="INSERT INTO ManagerTable ( firstTime, firstData, lastTime, lastData) VALUES ('${firstDateTime}','${firstData}', '${lastDateTime}', '${lastData}' )"
    $sqlcmd.CommandText = $sql
    $ret = $sqlcmd.ExecuteNonQuery()
    
    # 時刻を10分追加
    $dateTime = $dateTime.AddMinutes(10)
  }

  # トランザクション終了
  $transaction.Commit();

  $dayCnt++  
}
# SQLiteの切断
$sqlcmd.Dispose()
$sqlite.Close()
