import sys
import ctypes
import json

# Add the directory containing your .so file to the Python path
sys.path.append('../build/')

import libcuevm  # Now you can import your module as usual

def process_json(input_data, output_file):
    # Convert Python dictionary to JSON string
    # input_json_string = json.dumps(input_data).encode('utf-8')

    input_data = input_data[list(input_data.keys())[0]] # extract first value
    # Call the library function with the JSON string
    # print ("input data")
    # print (input_data)
    # result_json = libcuevm.print_dict(input_data)
    result_json = libcuevm.run_dict(input_data)
    json.dump(result_json, open(output_file, 'w'), indent=4)

import argparse 

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('input', type=str, help='path to json file')
    parser.add_argument('output', type=str, help='path to output json file')
    parser.add_argument('num_instances', type=int, default=1, help='number of instances')
    args = parser.parse_args()

    json_file = args.input
    num_instances = args.num_instances
    output_file = args.output

    input_data = json.loads(open(json_file).read())
    instance_data = input_data[list(input_data.keys())[0]]
    instance_data["transaction"]["data"] = instance_data["transaction"]["data"] * (num_instances//len(instance_data["transaction"]["data"]))
    instance_data["transaction"]["gasLimit"] = instance_data["transaction"]["gasLimit"] * (num_instances//len(instance_data["transaction"]["gasLimit"]))
    instance_data["transaction"]["value"] = instance_data["transaction"]["value"] * (num_instances//len(instance_data["transaction"]["value"]))
    # print (f'generated {len(instance_data["transaction"]["data"])} instances')
    process_json(input_data, output_file)
