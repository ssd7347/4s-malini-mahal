# Deploy to Vercel (builds locally, uploads dist/)
$env:PATH = "C:\Program Files\nodejs;C:\Users\sivas\AppData\Roaming\npm;$env:PATH"

Write-Host "Building frontend..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\frontend"
node node_modules\ember-cli\bin\ember build --environment=production
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!" -ForegroundColor Red; exit 1 }

# Copy vercel.json into dist so it is picked up during deploy
Copy-Item -Path "vercel.json" -Destination "dist\vercel.json" -Force

Write-Host "Deploying to Vercel..." -ForegroundColor Cyan
vercel deploy dist --prod --yes

Write-Host "Done!" -ForegroundColor Green
