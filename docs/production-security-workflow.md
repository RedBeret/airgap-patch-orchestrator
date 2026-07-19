# Production security workflow

The demo bundle is intentionally small and does not claim to contain a current
security fix. A production implementation must preserve vendor advisory metadata.

## Connected side

1. Synchronize approved BaseOS and AppStream repositories with metadata.
2. Record repository IDs, release version, architecture, advisory IDs, severity,
   package NEVRAs, build time, and builder identity.
3. Generate repository metadata without discarding `updateinfo.xml`.
4. Create the checksummed manifest.
5. Sign the manifest on an approved signing host.
6. Rehearse verification and package resolution with networking disabled.

## Transfer boundary

1. Record removable-media custody.
2. Scan the media according to local policy.
3. Compare the signed manifest digest through a separate trusted channel.

## Isolated side

1. Verify the detached signature using a pinned public key.
2. Verify every manifest entry and reject unexpected files.
3. Import into a quarantine repository.
4. Run assessment and obtain change approval.
5. Snapshot supported workloads.
6. Patch canaries, run application health checks, then continue serially.
7. Export evidence and remove the temporary repository configuration.

Package downgrade is not treated as universal rollback. Recovery should be based on
tested VM/LVM snapshots, application backups, or rebuild procedures appropriate to
the workload.
