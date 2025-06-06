"""
Insight management and notification system
"""

import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any
import os

logger = logging.getLogger(__name__)

class InsightManager:
    """Manage insights, alerts, and notifications"""
    
    def __init__(self, data_dir: str, ha_client, notification_service: str = "persistent_notification"):
        self.data_dir = data_dir
        self.ha_client = ha_client
        self.notification_service = notification_service
        self.insights_file = os.path.join(data_dir, 'insights', 'insights.json')
        
        # Ensure insights directory exists
        os.makedirs(os.path.dirname(self.insights_file), exist_ok=True)
        
        # Load existing insights
        self.insights = self._load_insights()
    
    def _load_insights(self) -> List[Dict[str, Any]]:
        """Load existing insights from file"""
        try:
            if os.path.exists(self.insights_file):
                with open(self.insights_file, 'r') as f:
                    data = json.load(f)
                    
                # Clean old insights (keep last 30 days)
                cutoff = datetime.now() - timedelta(days=30)
                recent_insights = [
                    insight for insight in data.get('insights', [])
                    if datetime.fromisoformat(insight.get('timestamp', '')) > cutoff
                ]
                return recent_insights
        except Exception as e:
            logger.error(f"Error loading insights: {e}")
        
        return []
    
    def _save_insights(self):
        """Save insights to file"""
        try:
            os.makedirs(os.path.dirname(self.insights_file), exist_ok=True)
            with open(self.insights_file, 'w') as f:
                json.dump({'insights': self.insights}, f, indent=2)
        except Exception as e:
            logger.error(f"Error saving insights: {e}")
    
    async def process_insight(self, analysis: Dict[str, Any]):
        """Process and handle a new insight from analysis"""
        try:
            # Create insight record
            insight = {
                'id': f"insight_{int(datetime.now().timestamp())}",
                'timestamp': datetime.now().isoformat(),
                'type': self._classify_insight_type(analysis),
                'confidence': analysis.get('confidence', 0.0),
                'summary': self._generate_summary(analysis),
                'details': analysis.get('insights', []),
                'changes_analyzed': analysis.get('changes_analyzed', 0),
                'requires_attention': analysis.get('requires_attention', False),
                'status': 'new'
            }
            
            # Add to insights list
            self.insights.append(insight)
            
            # Save insights
            self._save_insights()
            
            # Send notification if required
            if insight['requires_attention']:
                await self._send_notification(insight)
            
            logger.info(f"Processed insight: {insight['type']} (confidence: {insight['confidence']:.2f})")
            
        except Exception as e:
            logger.error(f"Error processing insight: {e}")
    
    def _classify_insight_type(self, analysis: Dict[str, Any]) -> str:
        """Classify the type of insight based on analysis"""
        insights = analysis.get('insights', [])
        
        # Simple classification based on keywords
        insight_text = ' '.join(insights).lower()
        
        if any(word in insight_text for word in ['security', 'door', 'lock', 'alarm', 'motion']):
            return 'security'
        elif any(word in insight_text for word in ['energy', 'power', 'consumption', 'efficiency']):
            return 'energy'
        elif any(word in insight_text for word in ['temperature', 'climate', 'hvac', 'heating', 'cooling']):
            return 'climate'
        elif any(word in insight_text for word in ['automation', 'script', 'performance', 'failed']):
            return 'automation'
        elif any(word in insight_text for word in ['device', 'battery', 'connectivity', 'health']):
            return 'device_health'
        else:
            return 'general'
    
    def _generate_summary(self, analysis: Dict[str, Any]) -> str:
        """Generate a concise summary of the insight"""
        insights = analysis.get('insights', [])
        
        if not insights:
            return "System monitoring detected activity requiring attention"
        
        # Take first insight as primary summary
        primary = insights[0]
        
        if len(insights) > 1:
            return f"{primary} (+{len(insights)-1} additional observations)"
        else:
            return primary
    
    async def _send_notification(self, insight: Dict[str, Any]):
        """Send notification for important insights"""
        try:
            title = f"Claude Watchdog: {insight['type'].title()} Alert"
            message = f"{insight['summary']}\n\nConfidence: {insight['confidence']:.0%}\nTime: {insight['timestamp']}"
            
            # Send via configured notification service
            if self.notification_service == "persistent_notification":
                # Use persistent notification service
                await self.ha_client.send_notification(
                    service="persistent_notification",
                    message=message,
                    title=title,
                    notification_id=f"claude_watchdog_{insight['id']}"
                )
            else:
                # Use regular notification service
                await self.ha_client.send_notification(
                    service=self.notification_service,
                    message=message,
                    title=title
                )
            
            logger.info(f"Notification sent for insight: {insight['id']}")
            
        except Exception as e:
            logger.error(f"Error sending notification: {e}")
    
    def get_recent_insights(self, hours: int = 24, insight_type: str = None) -> List[Dict[str, Any]]:
        """Get recent insights, optionally filtered by type"""
        cutoff = datetime.now() - timedelta(hours=hours)
        
        recent = [
            insight for insight in self.insights
            if datetime.fromisoformat(insight.get('timestamp', '')) > cutoff
        ]
        
        if insight_type:
            recent = [insight for insight in recent if insight.get('type') == insight_type]
        
        return sorted(recent, key=lambda x: x.get('timestamp', ''), reverse=True)
    
    def get_insight_statistics(self) -> Dict[str, Any]:
        """Get statistics about insights"""
        if not self.insights:
            return {
                'total_insights': 0,
                'attention_required': 0,
                'by_type': {},
                'average_confidence': 0.0
            }
        
        # Calculate statistics
        total = len(self.insights)
        attention_required = len([i for i in self.insights if i.get('requires_attention', False)])
        
        # Group by type
        by_type = {}
        confidences = []
        
        for insight in self.insights:
            insight_type = insight.get('type', 'unknown')
            by_type[insight_type] = by_type.get(insight_type, 0) + 1
            
            confidence = insight.get('confidence', 0.0)
            if confidence > 0:
                confidences.append(confidence)
        
        avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0
        
        return {
            'total_insights': total,
            'attention_required': attention_required,
            'by_type': by_type,
            'average_confidence': avg_confidence,
            'recent_24h': len(self.get_recent_insights(24)),
            'recent_7d': len(self.get_recent_insights(24 * 7))
        }
    
    def mark_insight_acknowledged(self, insight_id: str):
        """Mark an insight as acknowledged"""
        for insight in self.insights:
            if insight.get('id') == insight_id:
                insight['status'] = 'acknowledged'
                insight['acknowledged_at'] = datetime.now().isoformat()
                self._save_insights()
                logger.info(f"Insight {insight_id} marked as acknowledged")
                return True
        
        return False