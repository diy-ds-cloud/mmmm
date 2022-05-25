#!/bin/bash

# from https://github.com/jupyterhub/binderhub/blob/3ccb21af73b8a42ea44226b6e5cd5c8b94bf2fdc/ci/publish

# This script publishes the Helm chart to the JupyterHub Helm chart repo and
# pushes associated built docker images to Docker hub using chartpress.
# --------------------------------------------------------------------------

# Exit on errors, assert env vars, log commands
set -eux

PUBLISH_ARGS="--push --publish-chart\
    --builder docker-buildx \
    --platform linux/amd64 \
    "

# cd helm-chart
# chartpress use git to push to our Helm chart repository, which is the gh-pages
# branch of jupyterhub/helm-chart. We have installed a private SSH key within
# the ~/.ssh folder with permissions to push to jupyterhub/helm-chart.
if [[ $GITHUB_REF != refs/tags/* ]]; then
    # Using --extra-message, we help readers of merged PRs to know what version
    # they need to bump to in order to make use of the PR. This is enabled by a
    # GitHub notificaiton in the PR like "Github Action user pushed a commit to
    # jupyterhub/helm-chart that referenced this pull request..."
    #
    # ref: https://github.com/jupyterhub/chartpress#usage
    #
    # NOTE: GitHub merge commits contain a PR reference like #123. `sed` looks
    #       to extract either a PR reference like #123 or fall back to create a
    #       commit hash reference like @123abcd. Combined with GITHUB_REPOSITORY
    #       we craft a commit message like jupyterhub/binderhub#123 or
    #       jupyterhub/binderhub@123abcd which will be understood as a reference
    #       by GitHub.
    PR_OR_HASH=$(git log -1 --pretty=%h-%B | head -n1 | sed 's/^.*\(#[0-9]*\).*/\1/' | sed 's/^\([0-9a-f]*\)-.*/@\1/')
    LATEST_COMMIT_TITLE=$(git log -1 --pretty=%B | head -n1)
    EXTRA_MESSAGE="${GITHUB_REPOSITORY}${PR_OR_HASH} ${LATEST_COMMIT_TITLE}"
    chartpress $PUBLISH_ARGS --extra-message "${EXTRA_MESSAGE}"
else
    # Setting a tag explicitly enforces a rebuild if this tag had already been
    # built and we wanted to override it.
    LATEST_COMMIT_TITLE=$(git log -1 --pretty=%B | head -n1)
    chartpress $PUBLISH_ARGS --tag "${GITHUB_REF:10}" --extra-message "${LATEST_COMMIT_TITLE}"
fi

# Let us log the changes chartpress did, it should include replacements for
# fields in values.yaml, such as what tag for various images we are using.
git --no-pager diff --color=always
