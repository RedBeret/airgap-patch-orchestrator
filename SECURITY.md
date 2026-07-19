# Security policy

## Supported versions

Security fixes are applied to the latest release on `main`.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting for this repository. Do not open a
public issue for a suspected vulnerability, exposed credential, signature-bypass,
or path-validation problem.

Include the affected version, reproduction steps, expected behavior, observed
behavior, and whether the issue can modify or replace a patch bundle.

## Lab boundary

This repository is a training and portfolio lab. Checksums detect corruption but do
not authenticate a bundle publisher. Production use requires detached signature
verification, protected signing keys, approved vendor content, change control, and a
tested recovery process.
