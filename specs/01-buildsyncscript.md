---
name: "build s3 sync script"
description: "A script for sync s3 bucket with local folder"
agent: "agent"
model: "Claude Haiku 5.5"
---

The goal is to have a bash script for syncronize the s3 remote bucket with local copy

- Must have a config.env.local file to configure bucket name, local path to sync, aws profile and bucket folder path
- build the bash sccript to run s3 sync to get remote changes and or set changes to remote throught sync strategy
- add gitignore file to project 
- the folder to sync must be called same in local and remote.
- add readme fil to explain the use