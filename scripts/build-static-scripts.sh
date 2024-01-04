#!/usr/bin/bash

set -e

version="$(git rev-parse --short HEAD)"
release_name="zbg-${version}"
archive_suffix="-linux-$(uname -m).tar.gz"

echo "Building artifacts for ${release_name}"

worktree=$(git rev-parse --show-toplevel)
tmp_workspace="$(mktemp -d)"

if [ -f "_artifacts/${release_name}${archive_suffix}" ]; then
  echo "_artifacts/${release_name}${archive_suffix} already exists. You need to delete it to run this script."
  exit 2
fi

# Building a static distribution

pushd "${tmp_workspace}"
git clone -q "${worktree}" .
# add ocaml-option-no-compression to support ocaml.5.1.*
opam switch create . --no-install --deps-only --packages "ocaml-option-static,ocaml.5.0.0" -y
eval $(opam env)
opam pin . --no-action -y
opam install . --deps-only -y
dune build --profile=static -p zbg
mkdir -p artifacts/bin/
cp _build/default/bin/main.exe artifacts/bin/zbg
opam switch remove . -y
popd
mkdir -p _artifacts
mv "${tmp_workspace}/artifacts" "_artifacts/${release_name}"

# Creating the archive

rm -rf "${tmp_workspace}"
pushd _artifacts
tar czvf "${release_name}${archive_suffix}" "${release_name}"
rm -rf ${release_name}

popd
