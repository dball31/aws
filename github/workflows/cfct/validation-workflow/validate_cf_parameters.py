import json
import yaml
import sys

# -------------------------------------------------
# Helper: allow CFN intrinsic functions in YAML
# -------------------------------------------------
def ignore_cfn_tags(loader, node):
    """Ignore CFN intrinsic functions (!Ref, !Sub, etc.) and return as string"""
    return loader.construct_scalar(node)

# Add constructors for common CFN tags
for tag in ["!Ref", "!Sub", "!GetAtt", "!Join", "!FindInMap", "!ImportValue", "!Select", "!If", "!Equals", "!And", "!Or", "!Not"]:
    yaml.SafeLoader.add_constructor(tag, ignore_cfn_tags)

# -------------------------------------------------
# Load YAML or JSON CloudFormation template
# -------------------------------------------------
def load_template(path):
    with open(path, "r") as f:
        if path.endswith(".json"):
            return json.load(f)
        return yaml.safe_load(f)

# -------------------------------------------------
# Load JSON parameter file
# -------------------------------------------------
def load_param_file(path):
    with open(path, "r") as f:
        return json.load(f)

# -------------------------------------------------
# Main validation logic
# -------------------------------------------------
def main(template_path, param_file_path):
    # Load template & parameters
    template = load_template(template_path)
    params = load_param_file(param_file_path)

    # Extract template parameters
    template_params = template.get("Parameters", {})
    template_param_names = set(template_params.keys())

    # Normalize JSON param file into a dict
    # Expecting format: [{"ParameterKey": "...", "ParameterValue": "..."}]
    json_params = {p["ParameterKey"]: p["ParameterValue"] for p in params}
    json_param_names = set(json_params.keys())

    errors = []

    # 1. Check for extra parameters in JSON not in template
    extra = json_param_names - template_param_names
    for p in extra:
        errors.append(f"❌ Parameter '{p}' is in JSON but NOT in template: {template_path}")

    # 2. Check for required parameters missing from JSON
    for param_name, param_def in template_params.items():
        if "Default" not in param_def:
            if param_name not in json_param_names:
                errors.append(f"❌ Required parameter '{param_name}' missing from JSON file: {param_file_path}")

    # Report errors or success
    if errors:
        print("\n".join(errors))
        sys.exit(1)

    print(f"✅ Parameter file OK: {param_file_path}")

# -------------------------------------------------
# CLI entrypoint
# -------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: validate_cf_parameters.py <template-file> <parameter-file>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])