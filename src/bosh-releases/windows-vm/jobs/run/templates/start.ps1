while ($true)
{
  Write-Host "Run: <%= p("message") %>"
  Start-Sleep -s <%= p("sleep_interval") %>
}
