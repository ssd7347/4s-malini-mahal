# Deploy to Netlify (uses 0 build minutes — builds locally, uploads dist/)
$env:PATH = "C:\Program Files\nodejs;$env:PATH"

Write-Host "Building frontend..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\frontend"
node node_modules\ember-cli\bin\ember build --environment=production
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!" -ForegroundColor Red; exit 1 }

Write-Host "Deploying to Netlify..." -ForegroundColor Cyan
node "C:\Program Files\nodejs\node_modules\netlify-cli\bin\netlify.js" deploy --prod --dir=dist

Write-Host "Done!" -ForegroundColor Green
