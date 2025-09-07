#!/usr/bin/env python3
"""
Error Budget Calculator
Shows how error budgets work with real numbers
"""

def calculate_error_budget(slo_target, time_window_days=30):
    """Calculate error budget in minutes"""
    total_minutes = time_window_days * 24 * 60
    allowed_downtime = total_minutes * (1 - slo_target/100)
    return allowed_downtime

def burn_rate_impact(burn_rate, budget_minutes):
    """Calculate when budget will be exhausted at current burn rate"""
    normal_days = 30  # Normal budget period
    days_to_exhaustion = normal_days / burn_rate
    hours_to_exhaustion = days_to_exhaustion * 24
    
    return {
        'days': days_to_exhaustion,
        'hours': hours_to_exhaustion,
        'minutes': hours_to_exhaustion * 60
    }

def main():
    print("💰 Error Budget Calculator")
    print("=" * 50)
    
    # Payment Service SLO
    print("\n📊 Payment Service SLO: 99.9% availability")
    print("-" * 40)
    
    slo = 99.9
    budget_minutes = calculate_error_budget(slo)
    
    print(f"Monthly error budget: {budget_minutes:.1f} minutes")
    print(f"Daily budget: {budget_minutes/30:.1f} minutes")
    print(f"Hourly budget: {budget_minutes/30/24:.2f} minutes")
    
    # Burn rate scenarios
    print("\n🔥 Burn Rate Scenarios")
    print("-" * 40)
    
    burn_rates = [
        (14.4, "CRITICAL - Page immediately"),
        (6, "HIGH - Page within 15 min"),
        (3, "MEDIUM - Create ticket"),
        (1, "LOW - Monitor closely")
    ]
    
    for rate, severity in burn_rates:
        impact = burn_rate_impact(rate, budget_minutes)
        print(f"\nBurn rate: {rate}x")
        print(f"Severity: {severity}")
        print(f"Budget exhausted in: {impact['days']:.1f} days ({impact['hours']:.0f} hours)")
    
    # Real incident example
    print("\n💥 Example Incident Impact")
    print("-" * 40)
    
    outage_minutes = 12  # 12-minute outage
    budget_consumed = (outage_minutes / budget_minutes) * 100
    budget_remaining = budget_minutes - outage_minutes
    
    print(f"Incident duration: {outage_minutes} minutes")
    print(f"Budget consumed: {budget_consumed:.1f}%")
    print(f"Budget remaining: {budget_remaining:.1f} minutes ({100-budget_consumed:.1f}%)")
    print(f"Incidents allowed this month: {int(budget_minutes/outage_minutes)}")
    
    # Policy recommendations
    print("\n📋 Error Budget Policy")
    print("-" * 40)
    
    remaining_percent = 100 - budget_consumed
    if remaining_percent > 50:
        print("✅ Status: NORMAL OPERATIONS")
        print("   - Feature development allowed")
        print("   - Standard deployment procedures")
    elif remaining_percent > 25:
        print("⚠️  Status: INCREASED FOCUS")
        print("   - Extra testing required")
        print("   - Extended monitoring after deployments")
    elif remaining_percent > 10:
        print("🚫 Status: FEATURE FREEZE")
        print("   - Only bug fixes allowed")
        print("   - SRE approval for all changes")
    else:
        print("🆘 Status: EMERGENCY MODE")
        print("   - No deployments")
        print("   - All hands on reliability")

if __name__ == "__main__":
    main()