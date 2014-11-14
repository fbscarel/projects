#!/usr/bin/env bash

function pkg_shadow_depends() {
  depends="glibc"
}

function pkg_shadow() {
  USE="-audit"
  packages="sys-apps/attr sys-apps/acl sys-apps/shadow"
}
