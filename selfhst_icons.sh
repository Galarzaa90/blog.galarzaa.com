#!/usr/bin/env bash

set -euo pipefail

# Keep this list aligned with selfhst/... front matter and :selfhst-...:
# references in docs/. Icons are provided by selfh.st under CC BY 4.0:
# https://github.com/selfhst/icons
readonly ICONS=(
  adguard-home
  gokapi
  home-assistant
  plex
)

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ICON_DIR="${SCRIPT_DIR}/overrides/.icons/selfhst"
readonly UPSTREAM_REF="${SELFHST_ICONS_REF:-main}"
readonly BASE_URL="https://cdn.jsdelivr.net/gh/selfhst/icons@${UPSTREAM_REF}"

staging_dir="$(mktemp -d)"
trap 'rm -rf -- "${staging_dir}"' EXIT

mkdir -p -- "${ICON_DIR}"

for icon in "${ICONS[@]}"; do
  source_file="${staging_dir}/${icon}.source"
  output_file="${staging_dir}/${icon}.svg"

  if curl --fail --location --retry 3 --silent \
    --output "${source_file}" "${BASE_URL}/svg/${icon}-dark.svg"; then
    echo "Downloading ${icon}-dark.svg (monochrome)"
    sed -E \
      -e '0,/<svg[[:space:]]/s//<svg fill="currentColor" /' \
      -e 's/((fill|stroke|color|stop-color)[[:space:]]*:[[:space:]]*)#[0-9a-fA-F]{3,8}/\1currentColor/g' \
      -e 's/((fill|stroke|color|stop-color)=")#[0-9a-fA-F]{3,8}/\1currentColor/g' \
      "${source_file}" > "${output_file}"
  elif curl --fail --location --retry 3 --silent \
    --output "${source_file}" "${BASE_URL}/svg/${icon}-light.svg"; then
    echo "Downloading ${icon}-light.svg (monochrome)"
    sed -E \
      -e '0,/<svg[[:space:]]/s//<svg fill="currentColor" /' \
      -e 's/((fill|stroke|color|stop-color)[[:space:]]*:[[:space:]]*)#[0-9a-fA-F]{3,8}/\1currentColor/g' \
      -e 's/((fill|stroke|color|stop-color)=")#[0-9a-fA-F]{3,8}/\1currentColor/g' \
      "${source_file}" > "${output_file}"
  elif curl --fail --location --retry 3 --silent \
    --output "${output_file}" "${BASE_URL}/svg/${icon}.svg"; then
    echo "Downloading ${icon}.svg (colored)"
  else
    echo "Downloading ${icon}.png (colored fallback)"
    curl --fail --location --retry 3 --silent --show-error \
      --output "${source_file}" "${BASE_URL}/png/${icon}.png"
    printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><image width="512" height="512" href="data:image/png;base64,%s"/></svg>\n' \
      "$(base64 -w0 "${source_file}")" > "${output_file}"
  fi

  cp "${output_file}" "${ICON_DIR}/${icon}.svg"
done

echo "Installed ${#ICONS[@]} icons in ${ICON_DIR}"
