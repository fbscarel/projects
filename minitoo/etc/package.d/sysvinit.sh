#!/usr/bin/env bash

function do_sysvinit() {
  USE="netifrc minimal -ada -device-mapper -newnet -trace"
  packages="sys-apps/sysvinit sys-apps/openrc"
}
