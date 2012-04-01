(* virt-sysprep
 * Copyright (C) 2012 Red Hat Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *)

open Sysprep_operation

module G = Guestfs

let cron_spool_perform g root =
  Array.iter g#rm_rf (g#glob_expand "/var/spool/cron/*");
  []

let cron_spool_op = {
  name = "cron-spool";
  pod_description = "Remove user at-jobs and cron-jobs.";
  extra_args = [];
  perform = cron_spool_perform;
}

let () = register_operation cron_spool_op