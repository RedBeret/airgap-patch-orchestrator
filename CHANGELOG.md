# Changelog

## 1.0.0 - 2026-07-18

- Add Windows PowerShell and native WSL setup paths.
- Build and verify portable AlmaLinux RPM repository bundles.
- Reverify bundle contents immediately before every transfer.
- Roll updates through a canary and then the fleet one host at a time.
- Remove temporary repository configuration and transferred RPMs after each host.
- Record assessment and patch evidence as JSON.
- Add doctor, status, test, and teardown commands.
- Validate Python, shell, and Ansible content in GitHub Actions.
