"""
Home Assistant API client for state monitoring
"""

import aiohttp
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional

logger = logging.getLogger(__name__)

class HomeAssistantClient:
    """Client for interacting with Home Assistant API"""
    
    def __init__(self, url: str, token: str):
        self.url = url.rstrip('/')
        self.token = token
        self.session = None
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    async def _get_session(self):
        """Get or create HTTP session"""
        if self.session is None:
            self.session = aiohttp.ClientSession()
        return self.session
    
    async def close(self):
        """Close HTTP session"""
        if self.session:
            await self.session.close()
    
    async def get_current_state(self, scope: List[str] = None) -> Dict[str, Any]:
        """Get current state of all entities or filtered by scope"""
        try:
            session = await self._get_session()
            async with session.get(f'{self.url}/api/states', headers=self.headers) as response:
                if response.status == 200:
                    entities = await response.json()
                    
                    # Filter by monitoring scope if provided
                    if scope:
                        filtered = self._filter_entities_by_scope(entities, scope)
                        return {entity['entity_id']: entity for entity in filtered}
                    
                    return {entity['entity_id']: entity for entity in entities}
                else:
                    logger.error(f"Failed to get states: {response.status}")
                    return {}
                    
        except Exception as e:
            logger.error(f"Error getting current state: {e}")
            return {}
    
    async def get_recent_changes(self, since: Optional[datetime] = None, scope: List[str] = None) -> List[Dict]:
        """Get recent state changes from history"""
        if since is None:
            since = datetime.now() - timedelta(minutes=5)
        
        try:
            # Use history API to get changes
            session = await self._get_session()
            since_iso = since.isoformat()
            
            async with session.get(
                f'{self.url}/api/history/period/{since_iso}',
                headers=self.headers
            ) as response:
                if response.status == 200:
                    history = await response.json()
                    changes = self._extract_changes_from_history(history, scope)
                    logger.debug(f"Found {len(changes)} state changes since {since_iso}")
                    return changes
                else:
                    logger.error(f"Failed to get history: {response.status}")
                    return []
                    
        except Exception as e:
            logger.error(f"Error getting recent changes: {e}")
            return []
    
    def _filter_entities_by_scope(self, entities: List[Dict], scope: List[str]) -> List[Dict]:
        """Filter entities based on monitoring scope"""
        if not scope:
            return entities
        
        filtered = []
        for entity in entities:
            entity_id = entity.get('entity_id', '')
            domain = entity_id.split('.')[0] if '.' in entity_id else ''
            
            # Map scope to domains
            if 'climate' in scope and domain in ['climate', 'weather', 'sensor']:
                if any(keyword in entity_id.lower() for keyword in ['temperature', 'humidity', 'climate', 'thermostat']):
                    filtered.append(entity)
            
            if 'security' in scope and domain in ['binary_sensor', 'alarm_control_panel', 'lock', 'camera']:
                if any(keyword in entity_id.lower() for keyword in ['door', 'window', 'motion', 'alarm', 'lock', 'security']):
                    filtered.append(entity)
            
            if 'energy' in scope and domain in ['sensor', 'switch', 'light']:
                if any(keyword in entity_id.lower() for keyword in ['power', 'energy', 'consumption', 'watt']):
                    filtered.append(entity)
            
            if 'automation_performance' in scope and domain in ['automation', 'script']:
                filtered.append(entity)
        
        return filtered
    
    def _extract_changes_from_history(self, history: List[List[Dict]], scope: List[str] = None) -> List[Dict]:
        """Extract meaningful changes from history data"""
        changes = []
        
        for entity_history in history:
            if not entity_history:
                continue
                
            entity_id = entity_history[0].get('entity_id', '')
            
            # Skip if not in monitoring scope
            if scope and not self._entity_in_scope(entity_id, scope):
                continue
            
            # Look for state changes
            for i in range(1, len(entity_history)):
                prev_state = entity_history[i-1]
                curr_state = entity_history[i]
                
                if prev_state.get('state') != curr_state.get('state'):
                    changes.append({
                        'entity_id': entity_id,
                        'old_state': prev_state.get('state'),
                        'new_state': curr_state.get('state'),
                        'last_changed': curr_state.get('last_changed'),
                        'attributes': curr_state.get('attributes', {}),
                        'domain': entity_id.split('.')[0] if '.' in entity_id else ''
                    })
        
        return changes
    
    def _entity_in_scope(self, entity_id: str, scope: List[str]) -> bool:
        """Check if entity is in monitoring scope"""
        domain = entity_id.split('.')[0] if '.' in entity_id else ''
        
        scope_domains = {
            'climate': ['climate', 'weather', 'sensor'],
            'security': ['binary_sensor', 'alarm_control_panel', 'lock', 'camera'],
            'energy': ['sensor', 'switch', 'light'],
            'automation_performance': ['automation', 'script'],
            'device_health': ['sensor', 'binary_sensor'],
            'patterns': ['*']  # All entities for pattern analysis
        }
        
        for scope_item in scope:
            if scope_item in scope_domains:
                if '*' in scope_domains[scope_item] or domain in scope_domains[scope_item]:
                    return True
        
        return False
    
    async def send_notification(self, service: str, message: str, title: str = "Claude Watchdog", **kwargs):
        """Send notification through Home Assistant"""
        try:
            session = await self._get_session()
            
            payload = {
                'message': message,
                'title': title,
                **kwargs
            }
            
            async with session.post(
                f'{self.url}/api/services/notify/{service}',
                headers=self.headers,
                json=payload
            ) as response:
                if response.status == 200:
                    logger.info(f"Notification sent via {service}")
                    return True
                else:
                    logger.error(f"Failed to send notification: {response.status}")
                    return False
                    
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
            return False