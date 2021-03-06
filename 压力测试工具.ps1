$telnetlist=New-Object system.collections.arraylist
1..3000|%{
$socket = new-object System.Net.Sockets.TcpClient
$null=$telnetlist.add($socket)
}


"client列表完成，开始连接……"
$(get-date)

#异步并发连接服务器
#$conn={param($sess)$sess.Connect("192.168.100.153",80)}
$conn={param($sess)$sess.Connect("192.168.100.182",17711)}
$results=New-Object system.collections.arraylist
$rsp=[System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool()
[void]$rsp.SetMaxRunspaces(500)
[void]$rsp.SetMinRunspaces(100)
$rsp.Open()
foreach($session in $telnetlist){
$gpc=[powershell]::Create()
$gpc.RunspacePool=$rsp
[void]$gpc.AddScript($conn)
[void]$gpc.AddParameter("sess",$session)
$AsyncResult=$gpc.BeginInvoke()
$result=New-Object psobject
add-member -InputObject $result -membertype NoteProperty -name hostname -Value $session.hostname
add-member -InputObject $result -membertype NoteProperty -name msg -Value $null
add-member -InputObject $result -membertype NoteProperty -name result -Value $AsyncResult
add-member -InputObject $result -membertype NoteProperty -name thread -Value $gpc
[void]$results.add($result)
}
do{
sleep 10
$t=$Results|%{$_.result}|?{!($_.IsCompleted)}
Write-Host "总进程数$($Results.count) 完成数$($Results.count-$t.length) 未完成数$($t.length)……"
$(get-date)
}while($t)

#查看连接状态
#$Results|%{$_.result}
#回收进程池
foreach($thread in $Results){
$thread.msg=$thread.thread.EndInvoke($thread.result)
}
$rsp.Close()

$telnetlist|%{$_.Connected}|group

$telnetlist|%{$_.Close()}
Remove-Variable telnetlist