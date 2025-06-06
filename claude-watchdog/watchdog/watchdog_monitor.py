"""
Core monitoring loop and state management
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

logger = logging.getLogger(__name__)

class WatchdogMonitor:
    """Main monitoring service that coordinates all watchdog activities"""
    
    def __init__(self, ha_client, claude_analyzer, cost_tracker, insight_manager, config):
        self.ha_client = ha_client
        self.claude_analyzer = claude_analyzer
        self.cost_tracker = cost_tracker
        self.insight_manager = insight_manager
        self.config = config
        
        self.running = False
        self.state_buffer = StateBuffer(max_size=1000)
        self.last_check = None
        
    async def start_monitoring(self):
        """Start the main monitoring loop"""
        logger.info("Starting monitoring loop...")
        self.running = True
        
        # Initialize baseline state
        await self._establish_baseline()
        
        # Start monitoring loop
        while self.running:
            try:
                await self._monitoring_cycle()
                await asyncio.sleep(self.config['check_interval'])
                
            except Exception as e:
                logger.error(f"Monitoring cycle error: {e}")
                await asyncio.sleep(self.config['check_interval'])
    
    async def stop_monitoring(self):
        """Stop the monitoring loop"""
        logger.info("Stopping monitoring loop...")
        self.running = False
    
    async def _monitoring_cycle(self):
        """Execute one monitoring cycle"""
        cycle_start = datetime.now()
        
        # Check if we're within cost/API limits
        if not self.cost_tracker.can_make_request():
            logger.warning("Daily cost/API limit reached, skipping cycle")
            return
        
        # Get recent state changes from Home Assistant
        changes = await self.ha_client.get_recent_changes(
            since=self.last_check,
            scope=self.config['monitoring_scope']
        )
        
        if not changes:
            logger.debug("No state changes detected")
            self.last_check = cycle_start
            return
        
        # Add changes to state buffer
        self.state_buffer.add_changes(changes)
        
        # Analyze changes with Claude
        analysis = await self.claude_analyzer.analyze_changes(
            changes=changes,
            context=self.state_buffer.get_context(),
            monitoring_scope=self.config['monitoring_scope']
        )
        
        # Track API cost
        self.cost_tracker.record_request(analysis.get('cost_info', {}))
        
        # Process any insights or alerts
        if analysis.get('requires_attention', False):
            await self.insight_manager.process_insight(analysis)
        
        # Update learning patterns if enabled
        if self.config['enable_learning']:
            await self._update_patterns(changes, analysis)
        
        self.last_check = cycle_start
        logger.debug(f"Monitoring cycle completed in {datetime.now() - cycle_start}")
    
    async def _establish_baseline(self):
        """Establish baseline state for monitoring"""
        logger.info("Establishing baseline state...")
        
        try:
            # Get current state of all monitored entities
            current_state = await self.ha_client.get_current_state(
                scope=self.config['monitoring_scope']
            )
            
            self.state_buffer.set_baseline(current_state)
            self.last_check = datetime.now()
            
            logger.info(f"Baseline established with {len(current_state)} entities")
            
        except Exception as e:
            logger.error(f"Failed to establish baseline: {e}")
            raise
    
    async def _update_patterns(self, changes: List[Dict], analysis: Dict):
        """Update learned patterns based on analysis"""
        # TODO: Implement pattern learning
        # This would update stored patterns based on observed behavior
        pass

class StateBuffer:
    """Buffer to store recent state changes for context"""
    
    def __init__(self, max_size: int = 1000):
        self.max_size = max_size
        self.changes = []
        self.baseline = {}
    
    def add_changes(self, changes: List[Dict]):
        """Add new state changes to buffer"""
        self.changes.extend(changes)
        
        # Trim buffer if it exceeds max size
        if len(self.changes) > self.max_size:
            self.changes = self.changes[-self.max_size:]
    
    def set_baseline(self, state: Dict):
        """Set baseline state"""
        self.baseline = state
    
    def get_context(self, lookback_minutes: int = 60) -> Dict:
        """Get recent context for analysis"""
        cutoff = datetime.now() - timedelta(minutes=lookback_minutes)
        
        recent_changes = [
            change for change in self.changes
            if datetime.fromisoformat(change.get('last_changed', '')) > cutoff
        ]
        
        return {
            'baseline': self.baseline,
            'recent_changes': recent_changes,
            'change_count': len(recent_changes),
            'buffer_size': len(self.changes)
        }