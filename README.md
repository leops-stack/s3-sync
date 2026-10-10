# S3 Sync Script

This project provides a small Bash script to synchronize a local folder with a folder inside an S3 bucket by using `aws s3 sync`.

## Files

- `s3-sync.sh`: runs the sync
- `config.env.local`: local configuration for your bucket, folder, path, and AWS profile
- `.gitignore`: keeps local-only configuration out of version control

## Requirements

- Bash
- AWS CLI installed and configured
- An AWS profile with access to the target bucket

## Configuration

Edit `config.env.local` and set these values:

```bash
S3_BUCKET="your-bucket-name"
S3_BUCKET_FOLDER="your-folder-name"
LOCAL_SYNC_PATH="/absolute/path/to/your-folder-name"
AWS_PROFILE="dev"
```

`LOCAL_SYNC_PATH` and `S3_BUCKET_FOLDER` must point to folders with the same final name. For example:

- `S3_BUCKET_FOLDER="shared-assets"`
- `LOCAL_SYNC_PATH="/Users/you/work/shared-assets"`

## Usage

Pull remote changes from S3 to your local folder:

```bash
./s3-sync.sh pull
```

Push local changes to S3:

```bash
./s3-sync.sh push
```

Preview changes without writing anything:

```bash
./s3-sync.sh pull --dry-run
./s3-sync.sh push --dry-run
```

Delete files in the destination that no longer exist in the source:

```bash
./s3-sync.sh pull --delete
./s3-sync.sh push --delete
```

Use a custom config file:

```bash
./s3-sync.sh pull --config /path/to/config.env.local
```

## Notes

- `pull` syncs from `s3://bucket/folder` to your local folder
- `push` syncs from your local folder to `s3://bucket/folder`
- The script prints the AWS CLI command before running it
