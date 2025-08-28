import { useState } from 'react'
import './App.css'

function App() {
  const [activeSection, setActiveSection] = useState('dashboard')

  const menuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'providers', label: 'Providers', icon: '👨‍⚕️' },
    { id: 'verifications', label: 'Verifications', icon: '✅' },
    { id: 'users', label: 'User Management', icon: '👥' },
    { id: 'security', label: 'Security', icon: '🔒' },
    { id: 'settings', label: 'Settings', icon: '⚙️' },
  ]

  const stats = [
    { label: 'Total Providers', value: '1,247', icon: '👨‍⚕️', color: 'navy' },
    { label: 'Pending Verifications', value: '23', icon: '⏳', color: 'gold' },
    { label: 'Active Verifiers', value: '89', icon: '✅', color: 'navy' },
    { label: 'System Alerts', value: '3', icon: '⚠️', color: 'red' },
  ]

  const recentActivity = [
    { name: 'Dr. Ahmed Hassan', specialty: 'Cardiology', status: 'Pending', time: '2 hours ago' },
    { name: 'Dr. Fatima Al-Zahra', specialty: 'Pediatrics', status: 'Verified', time: '4 hours ago' },
    { name: 'Dr. Mohamed Salah', specialty: 'Orthopedics', status: 'Under Review', time: '6 hours ago' },
    { name: 'Dr. Nour El-Din', specialty: 'Neurology', status: 'Verified', time: '8 hours ago' },
  ]

  return (
    <div className="healthflow-admin">
      {/* Header */}
      <header className="admin-header">
        <div className="header-content">
          <div className="logo-section">
            <div className="logo-icon">HF</div>
            <div className="logo-text">
              <h1>HealthFlow</h1>
              <span>Registry Admin Portal</span>
            </div>
          </div>
          <div className="header-actions">
            <button className="logout-btn">🚪 Logout</button>
          </div>
        </div>
      </header>

      <div className="admin-layout">
        {/* Sidebar */}
        <aside className="admin-sidebar">
          <nav className="sidebar-nav">
            {menuItems.map((item) => (
              <button
                key={item.id}
                className={`nav-item ${activeSection === item.id ? 'active' : ''}`}
                onClick={() => setActiveSection(item.id)}
              >
                <span className="nav-icon">{item.icon}</span>
                <span className="nav-label">{item.label}</span>
              </button>
            ))}
          </nav>
        </aside>

        {/* Main Content */}
        <main className="admin-main">
          {activeSection === 'dashboard' && (
            <div className="dashboard">
              <div className="page-header">
                <h2>Dashboard Overview</h2>
                <p>Welcome to HealthFlow Registry Administration</p>
              </div>

              {/* Stats Grid */}
              <div className="stats-grid">
                {stats.map((stat, index) => (
                  <div key={index} className={`stat-card ${stat.color}`}>
                    <div className="stat-icon">{stat.icon}</div>
                    <div className="stat-content">
                      <div className="stat-value">{stat.value}</div>
                      <div className="stat-label">{stat.label}</div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Recent Activity */}
              <div className="content-grid">
                <div className="activity-section">
                  <h3>Recent Provider Registrations</h3>
                  <div className="activity-list">
                    {recentActivity.map((activity, index) => (
                      <div key={index} className="activity-item">
                        <div className="activity-info">
                          <div className="activity-name">{activity.name}</div>
                          <div className="activity-specialty">{activity.specialty}</div>
                          <div className="activity-time">{activity.time}</div>
                        </div>
                        <div className={`activity-status ${activity.status.toLowerCase().replace(' ', '-')}`}>
                          {activity.status}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="actions-section">
                  <h3>Quick Actions</h3>
                  <div className="action-buttons">
                    <button className="action-btn primary">➕ Add New Provider</button>
                    <button className="action-btn secondary">✅ Review Verifications</button>
                    <button className="action-btn secondary">📊 Generate Report</button>
                    <button className="action-btn secondary">⚙️ System Settings</button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeSection !== 'dashboard' && (
            <div className="page-content">
              <div className="page-header">
                <h2>{menuItems.find(item => item.id === activeSection)?.label}</h2>
                <p>This section is under development</p>
              </div>
              <div className="placeholder-content">
                <div className="placeholder-icon">
                  {menuItems.find(item => item.id === activeSection)?.icon}
                </div>
                <h3>Coming Soon</h3>
                <p>The {menuItems.find(item => item.id === activeSection)?.label} module will be available soon.</p>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  )
}

export default App

