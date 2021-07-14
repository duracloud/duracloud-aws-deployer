#!/usr/bin/env python3
###################################################
# This program generates a single cloud init file for the mill
# based on a template, a list of properties, and in/exclusion 
# files.  All the properties will be merged in the order they are 
# specified on the command line and then used to replace any key references
# in the template couched in ${key} format. All properties will be inserted below
# MILL_CONFIG if it is defined.  The exclusion and inclusion files will be inserted
# at BIT_EXCLUSIONS and BIT_INCLUSIONS respectively.

# Author: Daniel Bernstein | daniel.bernstein@lyrasis.org 
###################################################
import argparse
import re
import os
import collections
#define the load_props subroutine
def load_props(props, property_file): 
	for line in property_file: 
		stripped = line.strip() 
		if not stripped == "" and not stripped.startswith("#"): 
			key, value = stripped.split('=') 
			props[key] = value 
        		
	return props


#main program execution
parser = argparse.ArgumentParser()
parser.add_argument('-t', '--template', type=argparse.FileType('r'), required=True)
parser.add_argument('-p', '--property-files', nargs="+", type=argparse.FileType('r'), required=True)
parser.add_argument('-e', '--efs_domain', required=True)
parser.add_argument('-n', '--node_type', required=True)
parser.add_argument('-s', '--mill_s3_config_path', required=True)
parser.add_argument('-r', '--aws_region', required=True)
parser.add_argument('-o', '--output_file',  required=True)
parser.add_argument('-v', '--mill_version',  required=True)
args = parser.parse_args()

output_file = args.output_file

if not os.path.exists(os.path.dirname(output_file)):
	os.makedirs(os.path.dirname(output_file))
       
output = open(output_file, "w+");
	  
template = args.template.readlines();

props = {}

for f in args.property_files: 
	props = load_props(props,f.readlines())

props['nodeType'] = args.node_type
props['efsDnsName'] = args.efs_domain
props['millS3ConfigPath'] = args.mill_s3_config_path
props['awsRegion'] = args.aws_region
props['millVersion'] = args.mill_version

#sort the properties
props = collections.OrderedDict(sorted(props.items()))

# for each line in template
for line in template: 
	match = re.findall('\$\{([^}]+)\}', line, re.DOTALL) 
	if match: 
		for i in match: 
			value = props[i]
			line = line.replace('${'+i+'}', value) 
	output.write(line)

	

output.close()
