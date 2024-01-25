import os
import copy
import json

script_dir = os.path.dirname(__file__) #<-- absolute dir the script is in
rel_path_pkg = "../io_pmp_reg_pkg.sv"
abs_file_path = os.path.join(script_dir, rel_path_pkg)

types_to_clean = []

new_file_lines = []
typedefs_processed = False

def process_json():
    global types_to_clean

    # Opening JSON file
    file = open(os.path.join(script_dir, "pkg_config.json"))
    # returns JSON object as a dictionary
    data = json.load(file)
    
    file_to_edit = data["input_file"]
    out_file = data["output_file"]
    
    for type in data["types_to_clean"]:
        types_to_clean.append(copy.deepcopy(type["type_name"]))

    return file_to_edit, out_file

def main():
    global typedefs_processed

    temp_lines = []
    rel_path_file_to_edit, rel_path_out_file = process_json() # Get variable data from json

    abs_path_file_to_edit = os.path.join(script_dir, rel_path_file_to_edit)
    abs_path_out_file = os.path.join(script_dir, rel_path_out_file)

    # Manipulate initial typedefs
    with open(abs_path_file_to_edit, 'r') as file:
        for line in file:
            # clean initial typedefs
            if typedefs_processed == False:
                # Found a typedef
                if line.find('typedef') != -1 or line == "  // Register -> HW type\n":
                    # Process temp_lines
                    for temp_line in temp_lines:
                        for string in types_to_clean:
                            # Search the wanted strings in line, if found, clear the previous "line buffer"
                            if temp_line.find(string) != -1:
                                temp_lines.clear()
                
                    new_file_lines.extend(temp_lines) # Add everything to the new file buffer
                    temp_lines.clear()                # House keeping

                if line == "  // Register -> HW type\n": # If line contains this, no more typedef to clean
                    typedefs_processed = True
                    new_file_lines.append(line) # Add the missing line

                else:
                    if line.find("package iopmp_reg_pkg;") != -1:
                        temp_lines.append("package rv_iopmp_reg_pkg;\n")
                    else:
                        temp_lines.append(line)     # Not time to process, add line to temporary buffer

            else:
                found = False
                for string in types_to_clean:
                    # Search the wanted strings in line, if not found, add
                    if line.find(string) != -1:
                        found = True
                        break

                if not found:        
                    new_file_lines.append(line) # Append the line still

    new_file = open(abs_path_out_file, 'w')
    new_file.writelines(new_file_lines)
    new_file.close()

if __name__ == "__main__":
    main()