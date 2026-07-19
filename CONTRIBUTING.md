# Contributing

Keep changes focused and preserve the lab's fail-closed defaults.

## Development setup

From WSL:

```bash
./scripts/bootstrap.sh
./scripts/lab.sh doctor
./scripts/lab.sh test
```

From Windows PowerShell:

```powershell
pwsh ./scripts/bootstrap.ps1
pwsh ./scripts/lab.ps1 -Action Doctor
pwsh ./scripts/lab.ps1 -Action Test
```

For changes to patch orchestration, run the full integration sequence documented in
the README. Pull requests should explain the safety impact and include a negative-path
check when they change verification, approval, rollout, or cleanup behavior.

Never commit generated bundles, evidence reports, credentials, private keys, or
vendor RPMs.
