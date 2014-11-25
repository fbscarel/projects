#!/usr/bin/env bash

function pkg_ncurses() {
  USE="minimal -ada -debug -tinfo -trace" 
  packages="sys-libs/ncurses"
}
