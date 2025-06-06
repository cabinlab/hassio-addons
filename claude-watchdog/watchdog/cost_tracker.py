"""
Cost tracking and API usage management
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Dict, Any
import os

logger = logging.getLogger(__name__)

class CostTracker:
    """Track API costs and usage to stay within limits"""
    
    def __init__(self, data_dir: str, daily_limit: float = 1.00, max_calls: int = 1000):
        self.data_dir = data_dir
        self.daily_limit = daily_limit
        self.max_calls = max_calls
        self.cost_file = os.path.join(data_dir, 'costs', 'daily_costs.json')
        
        # Ensure costs directory exists
        os.makedirs(os.path.dirname(self.cost_file), exist_ok=True)
        
        # Load or initialize cost data
        self.cost_data = self._load_cost_data()
    
    def _load_cost_data(self) -> Dict[str, Any]:
        """Load existing cost data or create new"""
        try:
            if os.path.exists(self.cost_file):
                with open(self.cost_file, 'r') as f:
                    data = json.load(f)
                    
                # Clean old data (keep last 30 days)
                cutoff = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d')
                data['daily_costs'] = {
                    date: costs for date, costs in data.get('daily_costs', {}).items()
                    if date >= cutoff
                }
                return data
        except Exception as e:
            logger.error(f"Error loading cost data: {e}")
        
        return {
            'daily_costs': {},
            'monthly_total': 0.0,
            'last_reset': datetime.now().strftime('%Y-%m-%d')
        }
    
    def _save_cost_data(self):
        """Save cost data to file"""
        try:
            os.makedirs(os.path.dirname(self.cost_file), exist_ok=True)
            with open(self.cost_file, 'w') as f:
                json.dump(self.cost_data, f, indent=2)
        except Exception as e:
            logger.error(f"Error saving cost data: {e}")
    
    def record_request(self, cost_info: Dict[str, Any]):
        """Record an API request and its cost"""
        today = datetime.now().strftime('%Y-%m-%d')
        
        if today not in self.cost_data['daily_costs']:
            self.cost_data['daily_costs'][today] = {
                'total_cost': 0.0,
                'request_count': 0,
                'tokens_used': 0,
                'requests': []
            }
        
        daily_data = self.cost_data['daily_costs'][today]
        
        # Extract cost information
        estimated_cost = cost_info.get('estimated_cost', 0.0)
        tokens = cost_info.get('estimated_tokens', 0)
        model = cost_info.get('model', 'unknown')
        
        # Update daily totals
        daily_data['total_cost'] += estimated_cost
        daily_data['request_count'] += 1
        daily_data['tokens_used'] += tokens
        
        # Record individual request
        daily_data['requests'].append({
            'timestamp': datetime.now().isoformat(),
            'model': model,
            'tokens': tokens,
            'cost': estimated_cost
        })
        
        # Keep only last 100 requests per day
        if len(daily_data['requests']) > 100:
            daily_data['requests'] = daily_data['requests'][-100:]
        
        self._save_cost_data()
        
        logger.debug(f"Recorded API request: ${estimated_cost:.4f}, {tokens} tokens")
    
    def can_make_request(self) -> bool:
        """Check if we can make another API request within limits"""
        today = datetime.now().strftime('%Y-%m-%d')
        
        if today not in self.cost_data['daily_costs']:
            return True
        
        daily_data = self.cost_data['daily_costs'][today]
        
        # Check daily cost limit
        if daily_data['total_cost'] >= self.daily_limit:
            logger.warning(f"Daily cost limit reached: ${daily_data['total_cost']:.4f} >= ${self.daily_limit}")
            return False
        
        # Check daily request limit
        if daily_data['request_count'] >= self.max_calls:
            logger.warning(f"Daily request limit reached: {daily_data['request_count']} >= {self.max_calls}")
            return False
        
        return True
    
    def get_daily_usage(self, date: str = None) -> Dict[str, Any]:
        """Get usage statistics for a specific date"""
        if date is None:
            date = datetime.now().strftime('%Y-%m-%d')
        
        return self.cost_data['daily_costs'].get(date, {
            'total_cost': 0.0,
            'request_count': 0,
            'tokens_used': 0,
            'requests': []
        })
    
    def get_usage_summary(self) -> Dict[str, Any]:
        """Get overall usage summary"""
        today = datetime.now().strftime('%Y-%m-%d')
        daily_usage = self.get_daily_usage(today)
        
        # Calculate week and month totals
        week_total = 0.0
        month_total = 0.0
        
        for date, data in self.cost_data['daily_costs'].items():
            date_obj = datetime.strptime(date, '%Y-%m-%d')
            days_ago = (datetime.now() - date_obj).days
            
            if days_ago <= 7:
                week_total += data.get('total_cost', 0.0)
            if days_ago <= 30:
                month_total += data.get('total_cost', 0.0)
        
        return {
            'today': {
                'cost': daily_usage['total_cost'],
                'requests': daily_usage['request_count'],
                'limit_cost': self.daily_limit,
                'limit_requests': self.max_calls,
                'remaining_cost': max(0, self.daily_limit - daily_usage['total_cost']),
                'remaining_requests': max(0, self.max_calls - daily_usage['request_count'])
            },
            'week_total': week_total,
            'month_total': month_total,
            'can_make_request': self.can_make_request()
        }