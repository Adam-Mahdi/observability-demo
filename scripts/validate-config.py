#!/usr/bin/env python3
"""
Configuration Validator
Validates all YAML/JSON configurations for syntax and best practices
"""

import yaml
import json
import sys
from pathlib import Path

class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    END = '\033[0m'

def validate_yaml(file_path):
    """Validate YAML syntax and structure"""
    try:
        with open(file_path, 'r') as f:
            data = yaml.safe_load(f)
        return True, "Valid YAML syntax"
    except yaml.YAMLError as e:
        return False, f"Invalid YAML: {e}"

def validate_json(file_path):
    """Validate JSON syntax"""
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        return True, "Valid JSON syntax"
    except json.JSONDecodeError as e:
        return False, f"Invalid JSON: {e}"

def check_slo_thresholds(file_path):
    """Validate SLO thresholds are reasonable"""
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)
    
    issues = []
    for slo in data.get('slos', []):
        objective = slo.get('objective', 0)
        if objective < 95:
            issues.append(f"⚠️  SLO {slo['name']}: {objective}% seems too low")
        elif objective > 99.99:
            issues.append(f"⚠️  SLO {slo['name']}: {objective}% might be unrealistic")
    
    return issues

def check_burn_rates(file_path):
    """Validate burn rate configurations"""
    with open(file_path, 'r') as f:
        data = yaml.safe_load(f)
    
    issues = []
    for monitor in data.get('monitors', []):
        if 'multi_burn_rate_configurations' in monitor:
            for config in monitor['multi_burn_rate_configurations']:
                rate = config.get('burn_rate_threshold', 0)
                window = config.get('long_window', 'unknown')
                if rate > 20:
                    issues.append(f"⚠️  Very high burn rate {rate}x for {window} window")
    
    return issues

def main():
    print("🔍 Observability Configuration Validator")
    print("=" * 50)
    
    project_root = Path(__file__).parent.parent
    
    # Validate all YAML files
    print(f"\n{Colors.BLUE}Validating YAML files...{Colors.END}")
    yaml_files = project_root.glob('**/*.yaml') 
    yaml_files = list(yaml_files) + list(project_root.glob('**/*.yml'))
    
    for file in yaml_files:
        valid, message = validate_yaml(file)
        if valid:
            print(f"  {Colors.GREEN}✓{Colors.END} {file.relative_to(project_root)}")
        else:
            print(f"  {Colors.RED}✗{Colors.END} {file.relative_to(project_root)}: {message}")
    
    # Validate all JSON files
    print(f"\n{Colors.BLUE}Validating JSON files...{Colors.END}")
    json_files = project_root.glob('**/*.json')
    
    for file in json_files:
        valid, message = validate_json(file)
        if valid:
            print(f"  {Colors.GREEN}✓{Colors.END} {file.relative_to(project_root)}")
        else:
            print(f"  {Colors.RED}✗{Colors.END} {file.relative_to(project_root)}: {message}")
    
    # Check SLO configurations
    print(f"\n{Colors.BLUE}Checking SLO Best Practices...{Colors.END}")
    slo_file = project_root / 'datadog' / 'slos' / 'slo-definitions.yaml'
    if slo_file.exists():
        issues = check_slo_thresholds(slo_file)
        if issues:
            for issue in issues:
                print(f"  {Colors.YELLOW}{issue}{Colors.END}")
        else:
            print(f"  {Colors.GREEN}✓ All SLO targets look reasonable{Colors.END}")
    
    # Check burn rates
    print(f"\n{Colors.BLUE}Checking Burn Rate Configurations...{Colors.END}")
    monitor_file = project_root / 'datadog' / 'monitors' / 'alert-definitions.yaml'
    if monitor_file.exists():
        issues = check_burn_rates(monitor_file)
        if issues:
            for issue in issues:
                print(f"  {Colors.YELLOW}{issue}{Colors.END}")
        else:
            print(f"  {Colors.GREEN}✓ Burn rates follow Google SRE guidelines{Colors.END}")
    
    print(f"\n{Colors.GREEN}✅ Configuration validation complete!{Colors.END}")

if __name__ == "__main__":
    main()