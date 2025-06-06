#!/usr/bin/env python3
"""
Claude Watchdog - Intelligent Home Assistant Monitoring
Main monitoring service that runs continuously
"""

import asyncio
import os
import sys
import signal
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any

from watchdog_monitor import WatchdogMonitor
from ha_client import HomeAssistantClient
from claude_analyzer import ClaudeAnalyzer
from cost_tracker import CostTracker
from insight_manager import InsightManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

class ClaudeWatchdogService:
    """Main service class for Claude Watchdog"""
    
    def __init__(self):
        self.running = False
        self.monitor = None
        self.ha_client = None
        self.claude_analyzer = None
        self.cost_tracker = None
        self.insight_manager = None
        
        # Load configuration from environment
        self.config = self._load_config()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from environment variables"""
        return {
            'model': os.getenv('ANTHROPIC_MODEL', 'claude-3-5-haiku-20241022'),
            'check_interval': int(os.getenv('WATCHDOG_CHECK_INTERVAL', '30')),
            'insight_threshold': float(os.getenv('WATCHDOG_INSIGHT_THRESHOLD', '0.8')),
            'max_daily_calls': int(os.getenv('WATCHDOG_MAX_DAILY_CALLS', '1000')),
            'cost_limit': float(os.getenv('WATCHDOG_COST_LIMIT', '1.00')),
            'enable_learning': os.getenv('WATCHDOG_ENABLE_LEARNING', 'true').lower() == 'true',
            'monitoring_scope': self._parse_monitoring_scope(),
            'notification_service': os.getenv('WATCHDOG_NOTIFICATION_SERVICE', 'persistent_notification'),
            'data_dir': os.getenv('CLAUDE_WATCHDOG_DATA', '/config/claude-watchdog'),
            'ha_url': os.getenv('HA_URL', 'http://supervisor/core'),
            'ha_token': os.getenv('HASSIO_TOKEN', '')
        }
    
    def _parse_monitoring_scope(self) -> List[str]:
        """Parse monitoring scope from environment"""
        scope_str = os.getenv('WATCHDOG_MONITORING_SCOPE', '["climate","security","energy"]')
        try:
            import json
            return json.loads(scope_str)
        except:
            return ["climate", "security", "energy"]
    
    async def initialize(self):
        """Initialize all service components"""
        logger.info("Initializing Claude Watchdog components...")
        
        try:
            # Initialize Home Assistant client
            self.ha_client = HomeAssistantClient(
                url=self.config['ha_url'],
                token=self.config['ha_token']
            )
            
            # Initialize Claude analyzer
            self.claude_analyzer = ClaudeAnalyzer(
                model=self.config['model'],
                insight_threshold=self.config['insight_threshold']
            )
            
            # Initialize cost tracker
            self.cost_tracker = CostTracker(
                data_dir=self.config['data_dir'],
                daily_limit=self.config['cost_limit'],
                max_calls=self.config['max_daily_calls']
            )
            
            # Initialize insight manager
            self.insight_manager = InsightManager(
                data_dir=self.config['data_dir'],
                ha_client=self.ha_client,
                notification_service=self.config['notification_service']
            )
            
            # Initialize main monitor
            self.monitor = WatchdogMonitor(
                ha_client=self.ha_client,
                claude_analyzer=self.claude_analyzer,
                cost_tracker=self.cost_tracker,
                insight_manager=self.insight_manager,
                config=self.config
            )
            
            logger.info("All components initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize components: {e}")
            raise
    
    async def start(self):
        """Start the monitoring service"""
        logger.info("Starting Claude Watchdog monitoring service...")
        
        # Set up signal handlers for graceful shutdown
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
        
        self.running = True
        
        try:
            await self.initialize()
            await self.monitor.start_monitoring()
            
        except Exception as e:
            logger.error(f"Service error: {e}")
            self.running = False
            raise
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        logger.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
    
    async def stop(self):
        """Stop the monitoring service"""
        logger.info("Stopping Claude Watchdog service...")
        self.running = False
        
        if self.monitor:
            await self.monitor.stop_monitoring()

# Service entry point
async def main():
    """Main entry point for the service"""
    service = ClaudeWatchdogService()
    
    try:
        await service.start()
    except KeyboardInterrupt:
        logger.info("Service interrupted by user")
    except Exception as e:
        logger.error(f"Service failed: {e}")
        sys.exit(1)
    finally:
        await service.stop()

if __name__ == "__main__":
    asyncio.run(main())