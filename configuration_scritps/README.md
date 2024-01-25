The current script starts by generating a hjson file for use with the reggen tool. It does this using the different settings defined inside the config.json file. It then passes the generated file to the regmap_scripts which will create, and edit the reg_pkg file and get it ready for use.

The regmap file should not be changed with the one created by the reggen tool.