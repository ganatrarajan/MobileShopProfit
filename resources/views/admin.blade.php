<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mobile Profits — Admin Panel</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2563eb;
            --primary-hover: #1d4ed8;
            --bg-dark: #0f172a;
            --bg-card: #1e293b;
            --bg-body: #f8fafc;
            --text-main: #0f172a;
            --text-muted: #64748b;
            --border-color: #e2e8f0;
            --success: #16a34a;
            --warning: #d97706;
            --danger: #dc2626;
            --sidebar-width: 250px;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', sans-serif;
        }

        body {
            background-color: var(--bg-body);
            color: var(--text-main);
            height: 100vh;
            display: flex;
            overflow: hidden;
        }

        /* --- AUTH LOGIN SCREEN --- */
        #auth-screen {
            position: fixed;
            inset: 0;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
        }

        .login-card {
            background: #ffffff;
            width: 100%;
            max-width: 420px;
            padding: 36px;
            border-radius: 16px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2), 0 10px 10px -5px rgba(0, 0, 0, 0.1);
        }

        .login-header {
            text-align: center;
            margin-bottom: 24px;
        }

        .login-header h2 {
            font-size: 22px;
            font-weight: 700;
            color: #0f172a;
        }

        .login-header p {
            font-size: 13px;
            color: #64748b;
            margin-top: 4px;
        }

        .form-group {
            margin-bottom: 18px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #475569;
            margin-bottom: 6px;
        }

        .form-control {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 14px;
            outline: none;
            transition: border 0.2s;
        }

        .form-control:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }

        .btn-primary {
            width: 100%;
            padding: 12px;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: background 0.2s;
        }

        .btn-primary:hover {
            background: var(--primary-hover);
        }

        .alert-error {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
            padding: 10px 14px;
            border-radius: 8px;
            font-size: 13px;
            margin-bottom: 18px;
            display: none;
        }

        /* --- LAYOUT SIDEBAR & MAIN --- */
        #app-layout {
            display: flex;
            width: 100vw;
            height: 100vh;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: #0f172a;
            color: white;
            display: flex;
            flex-direction: column;
        }

        .sidebar-brand {
            padding: 24px 20px;
            font-size: 18px;
            font-weight: 700;
            letter-spacing: -0.5px;
            border-bottom: 1px solid #1e293b;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .sidebar-menu {
            flex: 1;
            padding: 16px 12px;
            overflow-y: auto;
        }

        .menu-category {
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            color: #64748b;
            padding: 12px 12px 6px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 11px 14px;
            border-radius: 8px;
            color: #94a3b8;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.15s;
            margin-bottom: 4px;

            text-decoration: none;
        }

        .nav-item:hover, .nav-item.active {
            background: #1e293b;
            color: white;
        }

        .nav-item.active {
            border-left: 3px solid var(--primary);
            background: rgba(37, 99, 235, 0.15);
            color: #60a5fa;
        }

        .sidebar-footer {
            padding: 16px 20px;
            border-top: 1px solid #1e293b;
            font-size: 13px;
        }

        .main-wrapper {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .top-header {
            height: 64px;
            background: white;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 28px;
        }

        .header-title {
            font-size: 18px;
            font-weight: 700;
        }

        .admin-profile {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: var(--primary);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
        }

        .content-body {
            flex: 1;
            padding: 24px 28px;
            overflow-y: auto;
        }

        /* --- DASHBOARD METRIC CARDS --- */
        .grid-4 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
            gap: 20px;
            margin-bottom: 24px;
        }

        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }

        .metric-title {
            font-size: 12px;
            font-weight: 600;
            color: var(--text-muted);
            text-transform: uppercase;
            margin-bottom: 8px;
        }

        .metric-value {
            font-size: 26px;
            font-weight: 700;
            color: var(--text-main);
        }

        .metric-sub {
            font-size: 12px;
            color: #16a34a;
            margin-top: 6px;
            font-weight: 500;
        }

        /* --- TABLES & CARDS --- */
        .card-table {
            background: white;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            overflow: hidden;
            margin-bottom: 24px;
        }

        .table-toolbar {
            padding: 16px 20px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
        }

        .search-box {
            position: relative;
            min-width: 260px;
        }

        .search-box input {
            width: 100%;
            padding: 8px 12px 8px 36px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            font-size: 13px;
        }

        .search-box svg {
            position: absolute;
            left: 10px;
            top: 50%;
            transform: translateY(-50%);
            width: 16px;
            height: 16px;
            fill: #94a3b8;
        }

        .filter-select {
            padding: 8px 12px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            font-size: 13px;
            background: white;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13.5px;
        }

        th {
            background: #f8fafc;
            text-align: left;
            padding: 12px 18px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            color: #64748b;
            border-bottom: 1px solid var(--border-color);
        }

        td {
            padding: 14px 18px;
            border-bottom: 1px solid var(--border-color);
            color: #334155;
        }

        tr:hover td {
            background: #f8fafc;
        }

        /* --- BADGES --- */
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 50px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }

        .badge-active { background: #dcfce7; color: #15803d; }
        .badge-inactive { background: #fee2e2; color: #b91c1c; }
        .badge-trial { background: #fef3c7; color: #b45309; }
        .badge-resolved { background: #e0e7ff; color: #4338ca; }

        /* --- MODAL DIALOG --- */
        .modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 2000;
        }

        .modal-card {
            background: white;
            border-radius: 12px;
            width: 100%;
            max-width: 540px;
            padding: 24px;
            box-shadow: 0 20px 25px -5px rgba(0,0,0,0.2);
        }

        .modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 1px solid var(--border-color);
        }

        .modal-header h3 {
            font-size: 16px;
            font-weight: 700;
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 20px;
            cursor: pointer;
            color: #64748b;
        }

        .pagination-bar {
            padding: 12px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 13px;
            color: var(--text-muted);
            border-top: 1px solid var(--border-color);
        }

        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
            border-radius: 6px;
            border: 1px solid var(--border-color);
            background: white;
            cursor: pointer;
        }

        .btn-danger-sm {
            background: #fee2e2;
            color: #b91c1c;
            border: none;
        }
    </style>
</head>
<body>

    <!-- 1. ADMIN AUTH LOGIN SCREEN -->
    <div id="auth-screen">
        <div class="login-card">
            <div class="login-header">
                <h2>Mobile Profits Admin</h2>
                <p>Sign in to your SaaS administrator panel</p>
            </div>
            <div id="login-alert" class="alert-error"></div>
            <form id="login-form" onsubmit="handleLogin(event)">
                <div class="form-group">
                    <label>Admin Mobile or Email</label>
                    <input type="text" id="login-input" class="form-control" placeholder="admin@mobileprofits.com" required>
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" id="login-password" class="form-control" placeholder="••••••••" required>
                </div>
                <button type="submit" class="btn-primary" id="login-btn">Sign In to Dashboard</button>
            </form>
        </div>
    </div>

    <!-- 2. MAIN ADMIN APP LAYOUT -->
    <div id="app-layout" style="display: none;">
        <!-- Sidebar Navigation -->
        <aside class="sidebar">
            <div class="sidebar-brand">
                <span>⚡ Mobile Profits Admin</span>
            </div>
            <div class="sidebar-menu">
                <div class="menu-category">Main Navigation</div>
                <a href="#dashboard" class="nav-item active" onclick="switchNav('dashboard')">📊 Dashboard</a>
                <a href="#shops" class="nav-item" onclick="switchNav('shops')">🏬 Shops Directory</a>
                <a href="#users" class="nav-item" onclick="switchNav('users')">👥 User Accounts</a>
                
                <div class="menu-category">SaaS Business</div>
                <a href="#subscriptions" class="nav-item" onclick="switchNav('subscriptions')">💳 Subscriptions</a>
                <a href="#plans" class="nav-item" onclick="switchNav('plans')">🏷️ Plans & Pricing</a>
                <a href="#revenue" class="nav-item" onclick="switchNav('revenue')">📈 Revenue Analytics</a>
                
                <div class="menu-category">Help & System</div>
                <a href="#support" class="nav-item" onclick="switchNav('support')">📞 Support Requests</a>
                <a href="#audit" class="nav-item" onclick="switchNav('audit')">📜 Audit Logs</a>
            </div>
            <div class="sidebar-footer">
                <button onclick="handleLogout()" class="btn-sm btn-danger-sm" style="width:100%;">Logout Admin</button>
            </div>
        </aside>

        <!-- Main Wrapper -->
        <div class="main-wrapper">
            <header class="top-header">
                <div class="header-title" id="page-title">Dashboard Overview</div>
                <div class="admin-profile">
                    <div class="avatar" id="admin-avatar">A</div>
                    <div>
                        <div style="font-weight:600; font-size:13px;" id="admin-name">Administrator</div>
                        <div style="font-size:11px; color:#64748b;" id="admin-role">Super Admin</div>
                    </div>
                </div>
            </header>

            <main class="content-body" id="content-area">
                <!-- Views loaded dynamically via JS -->
            </main>
        </div>
    </div>

    <!-- 3. MODAL DIALOG -->
    <div id="modal-container" class="modal-overlay">
        <div class="modal-card">
            <div class="modal-header">
                <h3 id="modal-title">Modal Title</h3>
                <button class="modal-close" onclick="closeModal()">×</button>
            </div>
            <div id="modal-body"></div>
        </div>
    </div>

    <script>
        const API_BASE = '/api/v1/admin';
        let authToken = localStorage.getItem('admin_token');

        // Check Initial Auth State
        window.addEventListener('DOMContentLoaded', () => {
            if (authToken) {
                verifyAdmin();
            } else {
                showAuthScreen();
            }
        });

        function showAuthScreen() {
            document.getElementById('auth-screen').style.display = 'flex';
            document.getElementById('app-layout').style.display = 'none';
        }

        async function verifyAdmin() {
            try {
                const res = await fetch(`${API_BASE}/auth/me`, {
                    headers: { 'Authorization': `Bearer ${authToken}`, 'Accept': 'application/json' }
                });
                const data = await res.json();
                if (res.ok && data.success) {
                    document.getElementById('auth-screen').style.display = 'none';
                    document.getElementById('app-layout').style.display = 'flex';
                    document.getElementById('admin-name').innerText = data.data.user.name;
                    document.getElementById('admin-role').innerText = data.data.user.role.toUpperCase();
                    document.getElementById('admin-avatar').innerText = data.data.user.name.charAt(0);
                    switchNav('dashboard');
                } else {
                    handleLogout();
                }
            } catch (err) {
                handleLogout();
            }
        }

        async function handleLogin(e) {
            e.preventDefault();
            const btn = document.getElementById('login-btn');
            const alert = document.getElementById('login-alert');
            alert.style.display = 'none';
            btn.innerText = 'Authenticating...';

            try {
                const res = await fetch(`${API_BASE}/auth/login`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    body: JSON.stringify({
                        login: document.getElementById('login-input').value,
                        password: document.getElementById('login-password').value
                    })
                });
                const data = await res.json();
                btn.innerText = 'Sign In to Dashboard';

                if (res.ok && data.success) {
                    authToken = data.data.token;
                    localStorage.setItem('admin_token', authToken);
                    verifyAdmin();
                } else {
                    alert.innerText = data.message || 'Invalid credentials or non-admin user.';
                    alert.style.display = 'block';
                }
            } catch (err) {
                btn.innerText = 'Sign In to Dashboard';
                alert.innerText = 'Connection error. Please try again.';
                alert.style.display = 'block';
            }
        }

        function handleLogout() {
            localStorage.removeItem('admin_token');
            authToken = null;
            showAuthScreen();
        }

        // Navigation Switcher
        function switchNav(route) {
            document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
            const activeNav = document.querySelector(`.nav-item[href="#${route}"]`);
            if (activeNav) activeNav.classList.add('active');

            const titleMap = {
                'dashboard': 'Dashboard Overview',
                'shops': 'Shops Directory',
                'users': 'User Accounts',
                'subscriptions': 'Subscriptions Management',
                'plans': 'Plans & Pricing',
                'revenue': 'Platform Revenue Analytics',
                'support': 'Support Tickets & Feedback',
                'audit': 'Admin Audit Action Logs'
            };
            document.getElementById('page-title').innerText = titleMap[route] || 'Admin Panel';

            if (route === 'dashboard') loadDashboardView();
            else if (route === 'shops') loadShopsView();
            else if (route === 'users') loadUsersView();
            else if (route === 'subscriptions') loadSubscriptionsView();
            else if (route === 'plans') loadPlansView();
            else if (route === 'revenue') loadRevenueView();
            else if (route === 'support') loadSupportView();
            else if (route === 'audit') loadAuditView();
        }

        // Helper API Fetcher
        async function apiFetch(endpoint, method = 'GET', body = null) {
            const opts = {
                method,
                headers: { 'Authorization': `Bearer ${authToken}`, 'Accept': 'application/json', 'Content-Type': 'application/json' }
            };
            if (body) opts.body = JSON.stringify(body);
            const res = await fetch(`${API_BASE}${endpoint}`, opts);
            return await res.json();
        }

        // 1. DASHBOARD VIEW
        async function loadDashboardView() {
            const content = document.getElementById('content-area');
            content.innerHTML = '<div style="padding:20px;">Loading overview metrics...</div>';
            const data = await apiFetch('/dashboard');

            if (!data.success) return;
            const m = data.data;

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Shops</div>
                        <div class="metric-value">${m.shops.total}</div>
                        <div class="metric-sub">${m.shops.active} Active | ${m.shops.new_month} New This Month</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Subscriptions</div>
                        <div class="metric-value">${m.subscriptions.active}</div>
                        <div class="metric-sub">${m.subscriptions.trial} Trial | ${m.subscriptions.expired} Expired</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Platform Revenue</div>
                        <div class="metric-value">₹${m.business.total_revenue.toLocaleString()}</div>
                        <div class="metric-sub">₹${m.business.revenue_this_month.toLocaleString()} This Month</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Platform Repairs & Sales</div>
                        <div class="metric-value">${m.usage.total_repairs} Repairs</div>
                        <div class="metric-sub">${m.usage.total_sales} Total Sales Recorded</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="font-weight:700; font-size:15px;">Recently Registered Shops</div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner</th>
                                <th>Mobile</th>
                                <th>Registered</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${m.recent_shops.map(s => `
                                <tr>
                                    <td><strong>${s.name}</strong></td>
                                    <td>${s.owner_name}</td>
                                    <td>${s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A')}</td>
                                    <td>${new Date(s.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        // 2. SHOPS VIEW
        async function loadShopsView(page = 1, search = '', status = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/shops?page=${page}&search=${search}&status=${status}`);
            if (!data.success) return;
            const shops = data.data.data;

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div class="search-box">
                            <input type="text" placeholder="Search by shop name, owner, mobile..." value="${search}" oninput="loadShopsView(1, this.value, '${status}')">
                        </div>
                        <select class="filter-select" onchange="loadShopsView(1, '${search}', this.value)">
                            <option value="">All Statuses</option>
                            <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                            <option value="deactivated" ${status === 'deactivated' ? 'selected' : ''}>Deactivated</option>
                        </select>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner</th>
                                <th>Contact</th>
                                <th>Registered</th>
                                <th>Subscription</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${shops.map(s => {
                                const mob = s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A');
                                return `
                                <tr>
                                    <td><strong>${s.name}</strong></td>
                                    <td>${s.owner_name}</td>
                                    <td>${mob}</td>
                                    <td>${new Date(s.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge badge-trial">${s.latest_subscription ? s.latest_subscription.status : 'Trial'}</span></td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></td>
                                    <td>
                                        <button class="btn-sm" onclick="openShopDetails(${s.id})">Details</button>
                                        <button class="btn-sm ${s.status === 'active' ? 'btn-danger-sm' : ''}" onclick="toggleShopStatus(${s.id}, '${s.status === 'active' ? 'deactivated' : 'active'}')">
                                            ${s.status === 'active' ? 'Deactivate' : 'Activate'}
                                        </button>
                                    </td>
                                </tr>
                            `}).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        async function openShopDetails(id) {
            const data = await apiFetch(`/shops/${id}`);
            if (!data.success) return;
            const s = data.data;

            const mob = s.contact_mobile || s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A');
            const email = s.contact_email || s.email || (s.user ? s.user.email : 'N/A');

            openModal(`Shop Details — ${s.name}`, `
                <div style="font-size:14px; line-height:1.6;">
                    <p><strong>Owner:</strong> ${s.owner_name}</p>
                    <p><strong>Mobile:</strong> ${mob} | <strong>Email:</strong> ${email}</p>
                    <p><strong>Registered:</strong> ${new Date(s.created_at).toLocaleString()}</p>
                    <p><strong>Account Status:</strong> <span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></p>
                    <hr style="margin:14px 0; border:0; border-top:1px solid #e2e8f0;">
                    <h4 style="font-size:13px; text-transform:uppercase; color:#64748b; margin-bottom:8px;">Platform Usage Statistics</h4>
                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px;">
                        <div style="background:#f8fafc; padding:10px; border-radius:8px;"><strong>Customers:</strong> ${s.customers_count}</div>
                        <div style="background:#f8fafc; padding:10px; border-radius:8px;"><strong>Repairs:</strong> ${s.repairs_count}</div>
                        <div style="background:#f8fafc; padding:10px; border-radius:8px;"><strong>Sales Invoices:</strong> ${s.sales_count}</div>
                        <div style="background:#f8fafc; padding:10px; border-radius:8px;"><strong>Devices Logged:</strong> ${s.devices_count}</div>
                    </div>
                </div>
            `);
        }

        async function toggleShopStatus(id, newStatus) {
            if (!confirm(`Are you sure you want to change this shop status to ${newStatus}?`)) return;
            const data = await apiFetch(`/shops/${id}/toggle-status`, 'POST', { status: newStatus, reason: 'Admin panel toggle' });
            if (data.success) {
                alert(`Shop has been ${newStatus}.`);
                loadShopsView();
            }
        }

        // 3. USERS VIEW
        async function loadUsersView(page = 1) {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/users?page=${page}`);
            if (!data.success) return;
            const users = data.data.data;

            content.innerHTML = `
                <div class="card-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Mobile / Email</th>
                                <th>Shop</th>
                                <th>Role</th>
                                <th>Created Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${users.map(u => `
                                <tr>
                                    <td><strong>${u.name}</strong></td>
                                    <td>${u.mobile} ${u.email ? `(${u.email})` : ''}</td>
                                    <td>${u.shop ? u.shop.name : 'N/A (Admin)'}</td>
                                    <td><span class="badge badge-resolved">${u.role}</span></td>
                                    <td>${new Date(u.created_at).toLocaleDateString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        // 4. SUBSCRIPTIONS VIEW
        async function loadSubscriptionsView() {
            const content = document.getElementById('content-area');
            const data = await apiFetch('/subscriptions');
            if (!data.success) return;
            const subs = data.data.data;

            content.innerHTML = `
                <div class="card-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop</th>
                                <th>Plan</th>
                                <th>Status</th>
                                <th>Payment</th>
                                <th>Expiry Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${subs.map(s => `
                                <tr>
                                    <td><strong>${s.shop ? s.shop.name : 'N/A'}</strong></td>
                                    <td>${s.plan ? s.plan.name : 'Trial Plan'}</td>
                                    <td><span class="badge badge-trial">${s.status}</span></td>
                                    <td><span class="badge ${s.payment_status === 'paid' ? 'badge-active' : 'badge-inactive'}">${s.payment_status}</span></td>
                                    <td>${s.expiry_date ? new Date(s.expiry_date).toLocaleDateString() : 'N/A'}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        // 5. PLANS VIEW
        async function loadPlansView() {
            const content = document.getElementById('content-area');
            const data = await apiFetch('/plans');
            if (!data.success) return;
            const plans = data.data;

            content.innerHTML = `
                <div class="grid-4">
                    ${plans.map(p => `
                        <div class="metric-card">
                            <div class="metric-title">${p.billing_period} Billing</div>
                            <div class="metric-value">₹${parseFloat(p.price).toLocaleString()}</div>
                            <div style="font-weight:700; font-size:16px; margin-top:4px;">${p.name}</div>
                            <div class="metric-sub">${p.subscriptions_count} Active Subscribers</div>
                        </div>
                    `).join('')}
                </div>
            `;
        }

        // 6. REVENUE VIEW
        async function loadRevenueView() {
            const content = document.getElementById('content-area');
            const data = await apiFetch('/revenue');
            if (!data.success) return;
            const r = data.data;

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">Total Platform Revenue</div>
                        <div class="metric-value">₹${r.total_revenue.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Revenue This Month</div>
                        <div class="metric-value">₹${r.revenue_this_month.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Paid Subscriptions</div>
                        <div class="metric-value">${r.paid_subscriptions_count}</div>
                    </div>
                </div>
            `;
        }

        // 7. SUPPORT VIEW
        async function loadSupportView() {
            const content = document.getElementById('content-area');
            const data = await apiFetch('/support');
            if (!data.success) return;
            const tickets = data.data.data;

            content.innerHTML = `
                <div class="card-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Type</th>
                                <th>Shop / Owner</th>
                                <th>Message</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${tickets.map(t => `
                                <tr>
                                    <td><span class="badge badge-trial">${t.type}</span></td>
                                    <td><strong>${t.shop ? t.shop.name : 'Unknown'}</strong></td>
                                    <td>${t.message}</td>
                                    <td>${new Date(t.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${t.status === 'resolved' ? 'badge-resolved' : 'badge-inactive'}">${t.status}</span></td>
                                    <td>
                                        ${t.status !== 'resolved' ? `<button class="btn-sm" onclick="resolveTicket(${t.id})">Mark Resolved</button>` : '—'}
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        async function resolveTicket(id) {
            const data = await apiFetch(`/support/${id}/status`, 'PUT', { status: 'resolved' });
            if (data.success) {
                loadSupportView();
            }
        }

        // 8. AUDIT LOGS VIEW
        async function loadAuditView() {
            const content = document.getElementById('content-area');
            const data = await apiFetch('/audit-logs');
            if (!data.success) return;
            const logs = data.data.data;

            content.innerHTML = `
                <div class="card-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Admin</th>
                                <th>Action</th>
                                <th>Details</th>
                                <th>IP Address</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${logs.map(l => `
                                <tr>
                                    <td><strong>${l.admin ? l.admin.name : 'Admin'}</strong></td>
                                    <td><span class="badge badge-resolved">${l.action}</span></td>
                                    <td>${l.details || '—'}</td>
                                    <td>${l.ip_address || '—'}</td>
                                    <td>${new Date(l.created_at).toLocaleString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        // MODAL HELPERS
        function openModal(title, htmlContent) {
            document.getElementById('modal-title').innerText = title;
            document.getElementById('modal-body').innerHTML = htmlContent;
            document.getElementById('modal-container').style.display = 'flex';
        }

        function closeModal() {
            document.getElementById('modal-container').style.display = 'none';
        }
    </script>
</body>
</html>
