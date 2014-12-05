#!/usr/bin/env bash

function pkg_thttpd_depends() {
  depends="glibc"
}

function pkg_thttpd() {
  packages="www-servers/thttpd"
}
