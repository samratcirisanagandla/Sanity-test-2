import yaml
import sys

def modify_values_yaml(file_path):
    # Open and load the values.yaml file
    with open(file_path, 'r') as stream:
        try:
            values = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)
            sys.exit(1)

    # Example modification: Add or update a key
    # Here you can customize what keys you want to modify or add
    values['new_key'] = 'new_value'  # Replace with actual key-value modifications as needed

    # Write the modified content back to the values.yaml file
    with open(file_path, 'w') as outfile:
        yaml.dump(values, outfile, default_flow_style=False)

if __name__ == "__main__":
    # Check if the correct number of arguments is provided
    if len(sys.argv) != 2:
        print("Usage: python3 convert.py <path-to-values.yaml>")
        sys.exit(1)

    # Call the function with the provided file path
    modify_values_yaml(sys.argv[1])
