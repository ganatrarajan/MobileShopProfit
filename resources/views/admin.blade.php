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
            border-bottom: 1px solid #1e293b;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .sidebar-brand span {
            color: #38bdf8;
        }

        .sidebar-menu {
            list-style: none;
            padding: 16px 10px;
            flex: 1;
            overflow-y: auto;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            color: #94a3b8;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            border-radius: 8px;
            margin-bottom: 4px;
            transition: all 0.2s;
        }

        .nav-item:hover {
            background: #1e293b;
            color: white;
        }

        .nav-item.active {
            background: var(--primary);
            color: white;
        }

        .user-footer {
            padding: 16px 20px;
            border-top: 1px solid #1e293b;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 13px;
        }

        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            background: #f8fafc;
        }

        .topbar {
            height: 64px;
            background: white;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 28px;
        }

        .topbar h1 {
            font-size: 18px;
            font-weight: 700;
            color: #0f172a;
        }

        .content-area {
            flex: 1;
            padding: 24px 28px;
            overflow-y: auto;
        }

        /* --- CARDS & TABLES --- */
        .grid-4 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
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
            text-transform: uppercase;
            color: #64748b;
        }

        .metric-value {
            font-size: 24px;
            font-weight: 700;
            color: #0f172a;
            margin: 8px 0 4px 0;
        }

        .metric-sub {
            font-size: 12px;
            color: #10b981;
            font-weight: 500;
        }

        .card-table {
            background: white;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            overflow: hidden;
        }

        .table-toolbar {
            padding: 16px 20px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
        }

        .search-box {
            position: relative;
            min-width: 260px;
        }

        .search-box input {
            width: 100%;
            padding: 9px 14px 9px 36px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            outline: none;
            transition: all 0.2s;
        }

        .search-box input:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        .search-box::before {
            content: '🔍';
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 13px;
            opacity: 0.5;
        }

        .filter-select {
            padding: 9px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            outline: none;
            background: white;
            color: #334155;
            cursor: pointer;
        }

        .filter-select:focus {
            border-color: var(--primary);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 14px;
        }

        th {
            background: #f8fafc;
            padding: 12px 20px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            color: #475569;
            border-bottom: 1px solid var(--border-color);
        }

        td {
            padding: 14px 20px;
            border-bottom: 1px solid var(--border-color);
            color: #334155;
        }

        tr:last-child td {
            border-bottom: none;
        }

        tr:hover td {
            background: #f8fafc;
        }

        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }

        .badge-active { background: #dcfce7; color: #15803d; }
        .badge-inactive { background: #fee2e2; color: #b91c1c; }
        .badge-trial { background: #fef3c7; color: #b45309; }
        .badge-resolved { background: #e0e7ff; color: #4338ca; }

        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
            font-weight: 600;
            border-radius: 6px;
            border: 1px solid #cbd5e1;
            background: white;
            color: #334155;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-sm:hover {
            background: #f1f5f9;
        }

        .btn-danger-sm {
            background: #fef2f2;
            color: #991b1b;
            border-color: #fecaca;
        }

        .btn-danger-sm:hover {
            background: #fee2e2;
        }

        .btn-success-sm {
            background: #f0fdf4;
            color: #166534;
            border-color: #bbf7d0;
        }

        .btn-success-sm:hover {
            background: #dcfce7;
        }

        /* MODAL */
        #modal-container {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(4px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1100;
        }

        .modal-content {
            background: white;
            width: 100%;
            max-width: 540px;
            border-radius: 14px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            overflow: hidden;
        }

        .modal-header {
            padding: 18px 24px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
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

        .modal-body {
            padding: 24px;
        }
    </style>
</head>
<body>

    <!-- LOGIN SCREEN -->
    <div id="auth-screen">
        <div class="login-card">
            <div class="login-header">
                <h2>Mobile Profits SaaS</h2>
                <p>Platform Administrator Sign In</p>
            </div>
            <div id="login-alert" class="alert-error"></div>
            <form onsubmit="handleLogin(event)">
                <div class="form-group">
                    <label>Admin Mobile / Email</label>
                    <input type="text" id="login-input" class="form-control" placeholder="7405989816 or admin@mobileprofits.com" value="7405989816" required>
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" id="password-input" class="form-control" placeholder="••••••••" value="12345678" required>
                </div>
                <button type="submit" class="btn-primary">Sign In to Dashboard</button>
            </form>
        </div>
    </div>

    <!-- MAIN APP LAYOUT -->
    <div id="app-layout" style="display: none;">
        <aside class="sidebar">
            <div class="sidebar-brand">
                📱 <span>Mobile Profits</span>
            </div>
            <ul class="sidebar-menu">
                <li><a href="#dashboard" class="nav-item active" onclick="switchNav('dashboard')">📊 Dashboard</a></li>
                <li><a href="#shops" class="nav-item" onclick="switchNav('shops')">🏪 Shops Directory</a></li>
                <li><a href="#users" class="nav-item" onclick="switchNav('users')">👥 User Accounts</a></li>
                <li><a href="#subscriptions" class="nav-item" onclick="switchNav('subscriptions')">💳 Subscriptions</a></li>
                <li><a href="#payments" class="nav-item" onclick="switchNav('payments')">🧾 Real Payments</a></li>
                <li><a href="#plans" class="nav-item" onclick="switchNav('plans')">🏷️ Plans & Pricing</a></li>
                <li><a href="#revenue" class="nav-item" onclick="switchNav('revenue')">📈 Revenue Analytics</a></li>
                <li><a href="#gateway" class="nav-item" onclick="switchNav('gateway')">⚙️ Gateway Settings</a></li>
                <li><a href="#support" class="nav-item" onclick="switchNav('support')">💬 Support & Tickets</a></li>
                <li><a href="#audit" class="nav-item" onclick="switchNav('audit')">🛡️ Audit Logs</a></li>
            </ul>
            <div class="user-footer">
                <span id="admin-name">Admin</span>
                <a href="#" style="color:#ef4444; text-decoration:none; font-weight:600;" onclick="logout()">Logout</a>
            </div>
        </aside>

        <main class="main-content">
            <header class="topbar">
                <h1 id="page-title">Dashboard Overview</h1>
            </header>
            <div id="content-area" class="content-area">
                <!-- Dynamic Content View Loaded Here -->
            </div>
        </main>
    </div>

    <!-- GLOBAL MODAL -->
    <div id="modal-container">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="modal-title">Modal Title</h3>
                <button class="modal-close" onclick="closeModal()">✕</button>
            </div>
            <div id="modal-body" class="modal-body">
                <!-- Dynamic Modal Content -->
            </div>
        </div>
    </div>

    <script>
        const API_BASE = '/api/v1/admin';
        let authToken = localStorage.getItem('admin_token');

        document.addEventListener('DOMContentLoaded', () => {
            if (authToken) {
                checkAuth();
            } else {
                showAuthScreen();
            }
        });

        function showAuthScreen() {
            document.getElementById('auth-screen').style.display = 'flex';
            document.getElementById('app-layout').style.display = 'none';
        }

        function showAppLayout() {
            document.getElementById('auth-screen').style.display = 'none';
            document.getElementById('app-layout').style.display = 'flex';
            loadDashboardView();
        }

        async function checkAuth() {
            const data = await apiFetch('/auth/me');
            if (data && data.success) {
                document.getElementById('admin-name').innerText = data.data.user.name || 'Admin';
                showAppLayout();
            } else {
                logout();
            }
        }

        async function handleLogin(e) {
            e.preventDefault();
            const login = document.getElementById('login-input').value;
            const password = document.getElementById('password-input').value;
            const alertBox = document.getElementById('login-alert');

            alertBox.style.display = 'none';

            try {
                const res = await fetch('/api/v1/admin/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    body: JSON.stringify({ login, password })
                });
                const data = await res.json();

                if (res.ok && data.success) {
                    authToken = data.data.token;
                    localStorage.setItem('admin_token', authToken);
                    document.getElementById('admin-name').innerText = data.data.user.name || 'Admin';
                    showAppLayout();
                } else {
                    alertBox.innerText = data.message || 'Invalid credentials or non-admin account';
                    alertBox.style.display = 'block';
                }
            } catch (err) {
                alertBox.innerText = 'Server connection error. Please try again.';
                alertBox.style.display = 'block';
            }
        }

        function logout() {
            if (authToken) {
                apiFetch('/auth/logout', 'POST');
            }
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
                'payments': 'Real Payment Transactions',
                'plans': 'Plans & Pricing',
                'revenue': 'Platform Revenue Analytics',
                'gateway': 'Razorpay Gateway Settings',
                'support': 'Support Tickets & Feedback',
                'audit': 'Admin Audit Action Logs'
            };
            document.getElementById('page-title').innerText = titleMap[route] || 'Admin Panel';

            if (route === 'dashboard') loadDashboardView();
            else if (route === 'shops') loadShopsView();
            else if (route === 'users') loadUsersView();
            else if (route === 'subscriptions') loadSubscriptionsView();
            else if (route === 'payments') loadPaymentsView();
            else if (route === 'plans') loadPlansView();
            else if (route === 'revenue') loadRevenueView();
            else if (route === 'gateway') loadGatewayView();
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

        let _searchDebounceTimer = null;
        function debounceSearch(fn) {
            if (_searchDebounceTimer) clearTimeout(_searchDebounceTimer);
            _searchDebounceTimer = setTimeout(fn, 350);
        }

        function renderPagination(meta, fnName, ...extraArgs) {
            if (!meta || meta.last_page <= 1) return '';
            const current = meta.current_page;
            const last = meta.last_page;
            const total = meta.total || 0;
            const from = meta.from || (((current - 1) * meta.per_page) + 1);
            const to = meta.to || Math.min(current * meta.per_page, total);
            const extraStr = extraArgs.map(a => typeof a === 'string' ? `'${a.replace(/'/g, "\'")}'` : a).join(', ');
            const comma = extraStr ? ', ' : '';

            return `
                <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 20px; border-top:1px solid #e2e8f0; font-size:13px; color:#64748b; background:#f8fafc;">
                    <div>Showing <strong>${from}-${to}</strong> of <strong>${total}</strong> records</div>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <button class="btn-sm" ${current <= 1 ? 'disabled style="opacity:0.4; cursor:not-allowed;"' : ''} onclick="${fnName}(${current - 1}${comma}${extraStr})">← Prev</button>
                        <span style="font-weight:600; color:#1e293b; padding:0 6px;">Page ${current} of ${last}</span>
                        <button class="btn-sm" ${current >= last ? 'disabled style="opacity:0.4; cursor:not-allowed;"' : ''} onclick="${fnName}(${current + 1}${comma}${extraStr})">Next →</button>
                    </div>
                </div>
            `;
        }

        // 1. DASHBOARD VIEW
        async function loadDashboardView() {
            const content = document.getElementById('content-area');
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading overview metrics...</div>';
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
        async function loadShopsView(page = 1, search = '', status = '', subStatus = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/shops?page=${page}&search=${encodeURIComponent(search)}&status=${status}&subscription_status=${subStatus}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const shops = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="shops-search-input" placeholder="Search shop name, owner, phone, email..." value="${search}" oninput="debounceSearch(() => loadShopsView(1, document.getElementById('shops-search-input').value, '${status}', '${subStatus}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadShopsView(1, '${search}', this.value, '${subStatus}')">
                                <option value="">Account: All Statuses</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active Account</option>
                                <option value="deactivated" ${status === 'deactivated' ? 'selected' : ''}>Deactivated Account</option>
                            </select>
                            <select class="filter-select" onchange="loadShopsView(1, '${search}', '${status}', this.value)">
                                <option value="">Plan: All Subscriptions</option>
                                <option value="active" ${subStatus === 'active' ? 'selected' : ''}>Active Plan</option>
                                <option value="trial" ${subStatus === 'trial' ? 'selected' : ''}>Trial</option>
                                <option value="expired" ${subStatus === 'expired' ? 'selected' : ''}>Expired</option>
                            </select>
                            ${(search || status || subStatus) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadShopsView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner Name</th>
                                <th>Contact Number</th>
                                <th>Registration Date</th>
                                <th>Subscription</th>
                                <th>Account Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${shops.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No shops found matching filter criteria.</td></tr>` : ''}
                            ${shops.map(s => {
                                const mob = s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A');
                                const sub = s.latest_subscription ? s.latest_subscription.status : 'trial';
                                return `
                                <tr>
                                    <td><strong>${s.name}</strong></td>
                                    <td>${s.owner_name}</td>
                                    <td>${mob}</td>
                                    <td>${new Date(s.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${sub === 'active' ? 'badge-active' : (sub === 'expired' ? 'badge-inactive' : 'badge-trial')}">${sub.toUpperCase()}</span></td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></td>
                                    <td>
                                        <button class="btn-sm" onclick="openShopDetails(${s.id})">Details</button>
                                        <button class="btn-sm ${s.status === 'active' ? 'btn-danger-sm' : 'btn-success-sm'}" onclick="toggleShopStatus(${s.id}, '${s.status === 'active' ? 'deactivated' : 'active'}')">
                                            ${s.status === 'active' ? 'Deactivate' : 'Activate'}
                                        </button>
                                    </td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    ${renderPagination(pageData, 'loadShopsView', search, status, subStatus)}
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
        async function loadUsersView(page = 1, search = '', role = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/users?page=${page}&search=${encodeURIComponent(search)}&role=${role}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const users = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="users-search-input" placeholder="Search user name, mobile, email..." value="${search}" oninput="debounceSearch(() => loadUsersView(1, document.getElementById('users-search-input').value, '${role}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadUsersView(1, '${search}', this.value)">
                                <option value="">All Roles</option>
                                <option value="owner" ${role === 'owner' ? 'selected' : ''}>Shop Owner</option>
                                <option value="admin" ${role === 'admin' ? 'selected' : ''}>SaaS Admin</option>
                            </select>
                            ${(search || role) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadUsersView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Mobile / Email</th>
                                <th>Associated Shop</th>
                                <th>User Role</th>
                                <th>Created Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${users.length === 0 ? `<tr><td colspan="5" style="text-align:center; padding:30px; color:#94a3b8;">No users found matching filter criteria.</td></tr>` : ''}
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
                    ${renderPagination(pageData, 'loadUsersView', search, role)}
                </div>
            `;
        }

        // 4. SUBSCRIPTIONS VIEW
        async function loadSubscriptionsView(page = 1, search = '', status = '', paymentStatus = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/subscriptions?page=${page}&search=${encodeURIComponent(search)}&status=${status}&payment_status=${paymentStatus}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const subs = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="subs-search-input" placeholder="Search by shop name, owner..." value="${search}" oninput="debounceSearch(() => loadSubscriptionsView(1, document.getElementById('subs-search-input').value, '${status}', '${paymentStatus}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSubscriptionsView(1, '${search}', this.value, '${paymentStatus}')">
                                <option value="">Status: All</option>
                                <option value="trial" ${status === 'trial' ? 'selected' : ''}>Trial</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                                <option value="expired" ${status === 'expired' ? 'selected' : ''}>Expired</option>
                                <option value="cancelled" ${status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                            </select>
                            <select class="filter-select" onchange="loadSubscriptionsView(1, '${search}', '${status}', this.value)">
                                <option value="">Payment: All</option>
                                <option value="paid" ${paymentStatus === 'paid' ? 'selected' : ''}>Paid</option>
                                <option value="pending" ${paymentStatus === 'pending' ? 'selected' : ''}>Pending</option>
                                <option value="free" ${paymentStatus === 'free' ? 'selected' : ''}>Free</option>
                            </select>
                            ${(search || status || paymentStatus) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSubscriptionsView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Current Plan</th>
                                <th>Subscription Status</th>
                                <th>Payment Status</th>
                                <th>Expiry Date</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${subs.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No subscriptions found matching filter criteria.</td></tr>` : ''}
                            ${subs.map(s => `
                                <tr>
                                    <td><strong>${s.shop ? s.shop.name : 'Shop #' + s.shop_id}</strong></td>
                                    <td>${s.plan ? s.plan.name : 'Default Plan'}</td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : (s.status === 'expired' ? 'badge-inactive' : 'badge-trial')}">${s.status.toUpperCase()}</span></td>
                                    <td><span class="badge ${s.payment_status === 'paid' ? 'badge-active' : 'badge-trial'}">${s.payment_status}</span></td>
                                    <td>${s.expiry_date ? new Date(s.expiry_date).toLocaleDateString() : 'N/A'}</td>
                                    <td>
                                        <button class="btn-sm" onclick="editSubscription(${s.id}, ${s.plan_id || 1}, '${s.status}', '${s.expiry_date ? s.expiry_date.substring(0, 10) : ''}', '${s.payment_status}')">Manage</button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    ${renderPagination(pageData, 'loadSubscriptionsView', search, status, paymentStatus)}
                </div>
            `;
        }

        async function editSubscription(id, currentPlanId, currentStatus, currentExpiry, currentPaymentStatus) {
            openModal('Manage Subscription', `
                <form onsubmit="saveSubscriptionUpdate(event, ${id})">
                    <div class="form-group">
                        <label>Subscription Status</label>
                        <select id="sub-edit-status" class="form-control">
                            <option value="trial" ${currentStatus === 'trial' ? 'selected' : ''}>Trial</option>
                            <option value="active" ${currentStatus === 'active' ? 'selected' : ''}>Active</option>
                            <option value="expired" ${currentStatus === 'expired' ? 'selected' : ''}>Expired</option>
                            <option value="cancelled" ${currentStatus === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Payment Status</label>
                        <select id="sub-edit-payment" class="form-control">
                            <option value="paid" ${currentPaymentStatus === 'paid' ? 'selected' : ''}>Paid</option>
                            <option value="pending" ${currentPaymentStatus === 'pending' ? 'selected' : ''}>Pending</option>
                            <option value="free" ${currentPaymentStatus === 'free' ? 'selected' : ''}>Free</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Expiry Date</label>
                        <input type="date" id="sub-edit-expiry" class="form-control" value="${currentExpiry}">
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Update Subscription</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveSubscriptionUpdate(e, id) {
            e.preventDefault();
            const body = {
                status: document.getElementById('sub-edit-status').value,
                payment_status: document.getElementById('sub-edit-payment').value,
                expiry_date: document.getElementById('sub-edit-expiry').value,
            };
            const data = await apiFetch(`/subscriptions/${id}/status`, 'PUT', body);
            if (data && data.success) {
                alert('Subscription updated successfully!');
                closeModal();
                loadSubscriptionsView();
            } else {
                alert(data.message || 'Failed to update subscription');
            }
        }

        // 5. PAYMENTS VIEW
        async function loadPaymentsView(page = 1, search = '', status = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/payments?page=${page}&search=${encodeURIComponent(search)}&status=${status}`);
            if (!data || data.status !== 'success') return;
            const pageData = data.data;
            const payments = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="payments-search-input" placeholder="Search order ID, payment ID, shop..." value="${search}" oninput="debounceSearch(() => loadPaymentsView(1, document.getElementById('payments-search-input').value, '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadPaymentsView(1, '${search}', this.value)">
                                <option value="">Status: All</option>
                                <option value="successful" ${status === 'successful' ? 'selected' : ''}>Successful</option>
                                <option value="pending" ${status === 'pending' ? 'selected' : ''}>Pending</option>
                                <option value="failed" ${status === 'failed' ? 'selected' : ''}>Failed</option>
                            </select>
                            ${(search || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadPaymentsView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Order ID</th>
                                <th>Payment ID</th>
                                <th>Amount</th>
                                <th>Method</th>
                                <th>Status</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${payments.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No payment records found matching filter criteria.</td></tr>` : ''}
                            ${payments.map(p => `
                                <tr>
                                    <td><strong>${p.shop ? p.shop.name : 'Shop #' + p.shop_id}</strong></td>
                                    <td><span style="font-family:monospace; font-size:12px;">${p.order_id}</span></td>
                                    <td><span style="font-family:monospace; font-size:12px;">${p.payment_id || '—'}</span></td>
                                    <td><strong>₹${parseFloat(p.amount).toFixed(2)}</strong></td>
                                    <td>${p.payment_method || 'Razorpay'}</td>
                                    <td><span class="badge ${p.status === 'successful' ? 'badge-active' : (p.status === 'failed' ? 'badge-inactive' : 'badge-trial')}">${p.status.toUpperCase()}</span></td>
                                    <td>${new Date(p.created_at).toLocaleString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    ${renderPagination(pageData, 'loadPaymentsView', search, status)}
                </div>
            `;
        }

        // 6. PLANS VIEW
        async function loadPlansView(search = '', status = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch('/plans');
            if (!data || !data.success) return;
            let plans = data.data || [];

            if (search) {
                const sLower = search.toLowerCase();
                plans = plans.filter(p => p.name.toLowerCase().includes(sLower) || p.billing_period.toLowerCase().includes(sLower));
            }
            if (status) {
                plans = plans.filter(p => p.status === status);
            }

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="plans-search-input" placeholder="Search plan name, billing period..." value="${search}" oninput="debounceSearch(() => loadPlansView(document.getElementById('plans-search-input').value, '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadPlansView('${search}', this.value)">
                                <option value="">Status: All</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                                <option value="inactive" ${status === 'inactive' ? 'selected' : ''}>Inactive</option>
                            </select>
                            ${(search || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadPlansView('', '')">Clear Filters</button>` : ''}
                            <button class="btn-primary" style="padding:8px 16px; width:auto; font-size:13px;" onclick="createPlanModal()">+ Create New Plan</button>
                        </div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Plan Name</th>
                                <th>Price</th>
                                <th>Billing Cycle</th>
                                <th>Sort Order</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${plans.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No plans found matching filter criteria.</td></tr>` : ''}
                            ${plans.map(p => `
                                <tr>
                                    <td><strong>${p.name}</strong></td>
                                    <td><strong>₹${parseFloat(p.price).toFixed(2)}</strong></td>
                                    <td>${p.billing_period}</td>
                                    <td>${p.sort_order || 0}</td>
                                    <td><span class="badge ${p.status === 'active' ? 'badge-active' : 'badge-inactive'}">${p.status}</span></td>
                                    <td>
                                        <button class="btn-sm" onclick="editPlanModal(${p.id}, '${p.name.replace(/'/g, "\'")}', ${p.price}, '${p.billing_period}', ${p.sort_order || 0}, '${p.status}')">Edit</button>
                                        <button class="btn-sm ${p.status === 'active' ? 'btn-danger-sm' : 'btn-success-sm'}" onclick="togglePlanStatus(${p.id})">
                                            ${p.status === 'active' ? 'Disable' : 'Enable'}
                                        </button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        function createPlanModal() {
            openModal('Create New Plan', `
                <form onsubmit="saveNewPlan(event)">
                    <div class="form-group">
                        <label>Plan Name</label>
                        <input type="text" id="new-plan-name" class="form-control" placeholder="e.g. Annual Pro Plan" required>
                    </div>
                    <div class="form-group">
                        <label>Price (INR)</label>
                        <input type="number" step="0.01" id="new-plan-price" class="form-control" placeholder="99.00" required>
                    </div>
                    <div class="form-group">
                        <label>Billing Period</label>
                        <select id="new-plan-period" class="form-control">
                            <option value="monthly">Monthly</option>
                            <option value="3_months">3 Months</option>
                            <option value="6_months">6 Months</option>
                            <option value="annual">Annual (12 Months)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Sort Order</label>
                        <input type="number" id="new-plan-sort" class="form-control" value="1">
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Create Plan</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveNewPlan(e) {
            e.preventDefault();
            const body = {
                name: document.getElementById('new-plan-name').value,
                price: parseFloat(document.getElementById('new-plan-price').value),
                billing_period: document.getElementById('new-plan-period').value,
                sort_order: parseInt(document.getElementById('new-plan-sort').value),
                status: 'active',
            };
            const res = await apiFetch('/plans', 'POST', body);
            if (res && res.success) {
                alert('Plan created successfully!');
                closeModal();
                loadPlansView();
            } else {
                alert(res.message || 'Failed to create plan');
            }
        }

        function editPlanModal(id, name, price, period, sort, status) {
            openModal('Edit Subscription Plan', `
                <form onsubmit="savePlanUpdate(event, ${id})">
                    <div class="form-group">
                        <label>Plan Name</label>
                        <input type="text" id="edit-plan-name" class="form-control" value="${name}" required>
                    </div>
                    <div class="form-group">
                        <label>Price (INR)</label>
                        <input type="number" step="0.01" id="edit-plan-price" class="form-control" value="${price}" required>
                    </div>
                    <div class="form-group">
                        <label>Billing Period</label>
                        <select id="edit-plan-period" class="form-control">
                            <option value="monthly" ${period === 'monthly' ? 'selected' : ''}>Monthly</option>
                            <option value="3_months" ${period === '3_months' ? 'selected' : ''}>3 Months</option>
                            <option value="6_months" ${period === '6_months' ? 'selected' : ''}>6 Months</option>
                            <option value="annual" ${period === 'annual' ? 'selected' : ''}>Annual (12 Months)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Sort Order</label>
                        <input type="number" id="edit-plan-sort" class="form-control" value="${sort}">
                    </div>
                    <div class="form-group">
                        <label>Status</label>
                        <select id="edit-plan-status" class="form-control">
                            <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                            <option value="inactive" ${status === 'inactive' ? 'selected' : ''}>Inactive</option>
                        </select>
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Update Plan</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function savePlanUpdate(e, id) {
            e.preventDefault();
            const body = {
                name: document.getElementById('edit-plan-name').value,
                price: parseFloat(document.getElementById('edit-plan-price').value),
                billing_period: document.getElementById('edit-plan-period').value,
                sort_order: parseInt(document.getElementById('edit-plan-sort').value),
                status: document.getElementById('edit-plan-status').value,
            };
            const res = await apiFetch(`/plans/${id}`, 'PUT', body);
            if (res && res.success) {
                alert('Plan updated successfully!');
                closeModal();
                loadPlansView();
            } else {
                alert(res.message || 'Failed to update plan');
            }
        }

        async function togglePlanStatus(id) {
            const res = await apiFetch(`/plans/${id}/toggle-status`, 'POST');
            if (res && res.success) {
                loadPlansView();
            } else {
                alert(res.message || 'Failed to toggle status');
            }
        }

        // 7. REVENUE VIEW
        async function loadRevenueView() {
            const content = document.getElementById('content-area');
            const data = await apiFetch('/revenue');
            if (!data || !data.success) return;
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
                    <div class="metric-card">
                        <div class="metric-title">Failed Payments</div>
                        <div class="metric-value">${r.failed_payments_count || 0}</div>
                    </div>
                </div>
            `;
        }

        // 8. PAYMENT GATEWAY SETTINGS VIEW
        async function loadGatewayView() {
            const content = document.getElementById('content-area');
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading gateway configuration...</div>';
            const res = await apiFetch('/settings/payment-gateway');
            if (!res || res.status !== 'success') return;
            const g = res.data;

            content.innerHTML = `
                <div class="card-table" style="padding:24px; max-width:650px;">
                    <h3 style="font-size:18px; font-weight:700; margin-bottom:16px;">Razorpay Gateway Settings</h3>
                    <div id="gw-alert" class="alert-error"></div>
                    <form onsubmit="saveGatewaySettings(event)">
                        <div class="form-group">
                            <label>Gateway Status</label>
                            <select id="gw-active" class="form-control">
                                <option value="1" ${g.active ? 'selected' : ''}>Enabled</option>
                                <option value="0" ${!g.active ? 'selected' : ''}>Disabled</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Environment Mode</label>
                            <select id="gw-mode" class="form-control">
                                <option value="test" ${g.mode === 'test' ? 'selected' : ''}>TEST Mode</option>
                                <option value="live" ${g.mode === 'live' ? 'selected' : ''}>LIVE Production Mode</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Razorpay Key ID</label>
                            <input type="text" id="gw-key-id" class="form-control" placeholder="rzp_test_xxxxxx" value="${g.key_id || ''}" required>
                        </div>
                        <div class="form-group">
                            <label>Razorpay Key Secret ${g.key_secret_configured ? '<span style="color:#16a34a; text-transform:none;">(Configured: ********)</span>' : '<span style="color:#dc2626; text-transform:none;">(Not Configured)</span>'}</label>
                            <input type="password" id="gw-key-secret" class="form-control" placeholder="Leave blank to keep existing key secret">
                        </div>
                        <div class="form-group">
                            <label>Razorpay Webhook Secret ${g.webhook_secret_configured ? '<span style="color:#16a34a; text-transform:none;">(Configured: ********)</span>' : '<span style="color:#64748b; text-transform:none;">(Optional)</span>'}</label>
                            <input type="password" id="gw-webhook-secret" class="form-control" placeholder="Leave blank to keep existing webhook secret">
                        </div>
                        <div class="form-group">
                            <label>Free Trial Period (Months)</label>
                            <input type="number" id="gw-trial" class="form-control" value="${g.trial_months || 3}" min="0" max="24" required>
                        </div>
                        <div style="display:flex; gap:12px; margin-top:24px;">
                            <button type="submit" class="btn-primary" style="flex:1;">Save Gateway Settings</button>
                            <button type="button" class="btn-sm" style="padding:12px 18px;" onclick="testGatewayConnection()">Test Connection</button>
                        </div>
                    </form>
                </div>
            `;
        }

        async function saveGatewaySettings(e) {
            e.preventDefault();
            const body = {
                key_id: document.getElementById('gw-key-id').value,
                mode: document.getElementById('gw-mode').value,
                currency: 'INR',
                active: document.getElementById('gw-active').value === '1',
                trial_months: parseInt(document.getElementById('gw-trial').value),
            };
            const sec = document.getElementById('gw-key-secret').value;
            const wh = document.getElementById('gw-webhook-secret').value;
            if (sec) body.key_secret = sec;
            if (wh) body.webhook_secret = wh;

            const res = await apiFetch('/settings/payment-gateway', 'POST', body);
            if (res && res.status === 'success') {
                alert('Razorpay Gateway Settings Saved Successfully!');
                loadGatewayView();
            } else {
                alert(res.message || 'Failed to save settings');
            }
        }

        async function testGatewayConnection() {
            const body = {
                key_id: document.getElementById('gw-key-id').value,
            };
            const sec = document.getElementById('gw-key-secret').value;
            if (sec) body.key_secret = sec;

            alert('Testing connection to Razorpay API...');
            const res = await apiFetch('/settings/payment-gateway/test', 'POST', body);
            if (res && res.success) {
                alert('SUCCESS: ' + res.message);
            } else {
                alert('FAILED: ' + (res.message || 'Authentication error'));
            }
        }

        // 9. SUPPORT VIEW
        async function loadSupportView(page = 1, search = '', status = '', type = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/support?page=${page}&search=${encodeURIComponent(search)}&status=${status}&type=${type}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const tickets = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="support-search-input" placeholder="Search subject, message, shop..." value="${search}" oninput="debounceSearch(() => loadSupportView(1, document.getElementById('support-search-input').value, '${status}', '${type}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSupportView(1, '${search}', this.value, '${type}')">
                                <option value="">Status: All</option>
                                <option value="open" ${status === 'open' ? 'selected' : ''}>Open</option>
                                <option value="in_progress" ${status === 'in_progress' ? 'selected' : ''}>In Progress</option>
                                <option value="resolved" ${status === 'resolved' ? 'selected' : ''}>Resolved</option>
                            </select>
                            <select class="filter-select" onchange="loadSupportView(1, '${search}', '${status}', this.value)">
                                <option value="">Type: All</option>
                                <option value="contact" ${type === 'contact' ? 'selected' : ''}>Contact</option>
                                <option value="problem" ${type === 'problem' ? 'selected' : ''}>Problem</option>
                                <option value="feedback" ${type === 'feedback' ? 'selected' : ''}>Feedback</option>
                            </select>
                            ${(search || status || type) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSupportView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
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
                            ${tickets.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No support tickets found matching filter criteria.</td></tr>` : ''}
                            ${tickets.map(t => `
                                <tr>
                                    <td><span class="badge badge-trial">${t.type}</span></td>
                                    <td><strong>${t.shop ? t.shop.name : 'Unknown Shop'}</strong></td>
                                    <td>${t.message}</td>
                                    <td>${new Date(t.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${t.status === 'resolved' ? 'badge-resolved' : 'badge-inactive'}">${t.status}</span></td>
                                    <td>
                                        ${t.status !== 'resolved' ? `<button class="btn-sm btn-success-sm" onclick="resolveTicket(${t.id})">Mark Resolved</button>` : '—'}
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    ${renderPagination(pageData, 'loadSupportView', search, status, type)}
                </div>
            `;
        }

        async function resolveTicket(id) {
            const data = await apiFetch(`/support/${id}/status`, 'PUT', { status: 'resolved' });
            if (data.success) {
                loadSupportView();
            }
        }

        // 10. AUDIT LOGS VIEW
        async function loadAuditView(page = 1, search = '', action = '') {
            const content = document.getElementById('content-area');
            const data = await apiFetch(`/audit-logs?page=${page}&search=${encodeURIComponent(search)}&action=${action}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const logs = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="audit-search-input" placeholder="Search details, IP, admin name..." value="${search}" oninput="debounceSearch(() => loadAuditView(1, document.getElementById('audit-search-input').value, '${action}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadAuditView(1, '${search}', this.value)">
                                <option value="">Action: All Actions</option>
                                <option value="ACTIVATE_SHOP" ${action === 'ACTIVATE_SHOP' ? 'selected' : ''}>Activate Shop</option>
                                <option value="DEACTIVATE_SHOP" ${action === 'DEACTIVATE_SHOP' ? 'selected' : ''}>Deactivate Shop</option>
                                <option value="UPDATE_SUBSCRIPTION" ${action === 'UPDATE_SUBSCRIPTION' ? 'selected' : ''}>Update Subscription</option>
                                <option value="update_payment_gateway_settings" ${action === 'update_payment_gateway_settings' ? 'selected' : ''}>Update Gateway</option>
                                <option value="UPDATE_SUPPORT_STATUS" ${action === 'UPDATE_SUPPORT_STATUS' ? 'selected' : ''}>Support Status</option>
                            </select>
                            ${(search || action) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadAuditView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Admin User</th>
                                <th>Action Taken</th>
                                <th>Action Details</th>
                                <th>IP Address</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${logs.length === 0 ? `<tr><td colspan="5" style="text-align:center; padding:30px; color:#94a3b8;">No audit logs found matching filter criteria.</td></tr>` : ''}
                            ${logs.map(l => `
                                <tr>
                                    <td><strong>${l.admin ? l.admin.name : 'Admin System'}</strong></td>
                                    <td><span class="badge badge-resolved">${l.action}</span></td>
                                    <td>${l.details || '—'}</td>
                                    <td>${l.ip_address || '—'}</td>
                                    <td>${new Date(l.created_at).toLocaleString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    ${renderPagination(pageData, 'loadAuditView', search, action)}
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
