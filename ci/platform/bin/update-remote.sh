#!/usr/bin/env bash
git remote set-url $($(git remote) | head -1) $git_url
