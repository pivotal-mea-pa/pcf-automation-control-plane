while ($true)
{
  Write-Host "Run: <%= p("enable_rdp.enabled") %>"
  Start-Sleep -s <%= p("sleep_interval") %>
}
