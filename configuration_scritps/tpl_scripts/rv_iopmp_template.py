#!/usr/bin/env python3
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

r"""Mako template to hjson register description
"""
import sys
import os
import argparse
import json
import copy
from io import StringIO

from mako.template import Template

# relative path to tpl file, and desired output
files_to_generate = []

script_dir = os.path.dirname(__file__) #<-- absolute dir the script is in

parameters = {
  "version"   : 0,
  "model"     :   0,
  "enable_tor": 1,
  "enable_sps": 0,
  "enable_usr_cfg" : 0,
  "entry_offset"   : 8192,
  "domains"        : 4,
  "entries"        : 16,
  "sources"        : 4
}

def bool_to_int(value):
   print(value)
   return 1 if value == True else 0


def process_json():
    global files_to_generate

    # Opening JSON file
    file = open(os.path.join(script_dir, "config.json"))
    # returns JSON object as a dictionary
    data = json.load(file)
    
    if "version" in data:
       parameters["version"] = data["version"]
    if "model" in data:
       parameters["model"] = data["model"]
    if "enable_tor" in data:
       parameters["enable_tor"] = bool_to_int(data["enable_tor"])
    if "enable_sps" in data:
       parameters["enable_sps"] = bool_to_int(data["enable_sps"])
    if "enable_usr_cfg" in data:
       parameters["enable_usr_cfg"] = bool_to_int(data["enable_usr_cfg"])
    if "entry_offset" in data:
       parameters["entry_offset"] = data["entry_offset"]
    if "domains" in data:
       parameters["domains"] = data["domains"] 
    if "entries" in data:
       parameters["entries"] = data["entries"] 
    if "sources" in data:
       parameters["sources"] = data["sources"] 

    for file in data["files_to_generate"]:
       tmp = []
       tmp.append(file["input_file"])
       tmp.append(file["output_file"])

       files_to_generate.append(copy.deepcopy(tmp))


def main():
    process_json()
    for file in files_to_generate:
       # Determine output: if stdin then stdout if not then ??
       out = StringIO()

       reg_tpl = Template(filename=script_dir + "/" + file[0])
       out.write(reg_tpl.render(
                                   version=parameters["version"],
                                   enable_tor=parameters["enable_tor"],
                                   enable_sps=parameters["enable_sps"],
                                   enable_usr_cfg=parameters["enable_usr_cfg"],
                                   model=parameters["model"],
                                   nr_mds=parameters["domains"],
                                   entry_offset=parameters["entry_offset"],
                                   nr_entries=parameters["entries"],
                                   nr_sources=parameters["sources"]))

       abs_file_path = os.path.join(script_dir, file[1])
       gen_file = open(abs_file_path, "w")
       gen_file.write(out.getvalue())
       gen_file.close()


    out.close()

if __name__ == "__main__":
    main()

