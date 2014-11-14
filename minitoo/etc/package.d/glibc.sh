#!/usr/bin/env bash

function pkg_glibc() {
  USE="cracklib -gd -static-libs"
  packages="sys-libs/zlib sys-libs/timezone-data sys-libs/db sys-libs/cracklib sys-libs/glibc sys-libs/pam sys-auth/pambase"
}
